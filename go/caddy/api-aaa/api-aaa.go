package apiaaa

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"time"

	"github.com/inverse-inc/go-utils/log"
	"github.com/inverse-inc/go-utils/sharedutils"
	"github.com/inverse-inc/go-utils/statsd"
	"github.com/inverse-inc/packetfence/go/api-frontend/aaa"
	"github.com/inverse-inc/packetfence/go/caddy/caddy"
	"github.com/inverse-inc/packetfence/go/caddy/caddy/caddyhttp/httpserver"
	"github.com/inverse-inc/packetfence/go/panichandler"
	"github.com/inverse-inc/packetfence/go/pfconfigdriver"
	"github.com/julienschmidt/httprouter"
)

// Register the plugin in caddy
func init() {
	caddy.RegisterPlugin("api-aaa", caddy.Plugin{
		ServerType: "http",
		Action:     setup,
	})
}

type PrettyTokenInfo struct {
	AdminActions []string  `json:"admin_actions"`
	AdminRoles   []string  `json:"admin_roles"`
	Username     string    `json:"username"`
	ExpiresAt    time.Time `json:"expires_at"`
}

type ApiAAAHandler struct {
	Next               httpserver.Handler
	router             *httprouter.Router
	systemBackend      *aaa.MemAuthenticationBackend
	webservicesBackend *aaa.MemAuthenticationBackend
	authentication     *aaa.TokenAuthenticationMiddleware
	authorization      *aaa.TokenAuthorizationMiddleware
	noAuthPaths        map[string]bool
}

// Setup the api-aaa middleware
// Also loads the pfconfig resources and registers them in the pool
func setup(c *caddy.Controller) error {
	ctx := log.LoggerNewContext(context.Background())

	noAuthPaths := map[string]bool{}
	tokenBackendArgs := []string{}
	var err error
	for c.Next() {
		for c.NextBlock() {
			switch c.Val() {
			case "no_auth":
				args := c.RemainingArgs()

				if len(args) != 1 {
					return c.ArgErr()
				} else {
					path := args[0]
					noAuthPaths[path] = true
					fmt.Println("The following path will not be authenticated via the api-aaa module", path)
				}
			case "session_backend":
				args := c.RemainingArgs()

				if len(args) == 0 {
					return c.ArgErr()
				}

				tokenBackendArgs, err = validateTokenArgs(args)
				if err != nil {
					return err
				}

			default:
				return c.ArgErr()
			}
		}
	}

	apiAAA, err := buildApiAAAHandler(ctx, tokenBackendArgs)
	apiAAA.noAuthPaths = noAuthPaths

	if err != nil {
		return err
	}

	httpserver.GetConfig(c).AddMiddleware(func(next httpserver.Handler) httpserver.Handler {
		apiAAA.Next = next
		return apiAAA
	})

	return nil
}

func hasDuplicate(a []string) bool {
	dups := map[string]struct{}{}
	for _, i := range a {
		if _, found := dups[i]; found {
			return true
		}
		dups[i] = struct{}{}
	}
	return false
}

func validateTokenArgs(args []string) ([]string, error) {
	if hasDuplicate(args) {
		return nil, errors.New("Cannot defined a backend type multiple times")
	}

	for _, i := range args {
		switch i {
		default:
			err := fmt.Errorf("Invalid session_backend type '%s'", i)
			return nil, err
		case "mem", "redis", "db":
			break
		}
	}
	return args, nil
}

// Build the ApiAAAHandler which will initialize the cache and instantiate the router along with its routes
func buildApiAAAHandler(ctx context.Context, tokenBackendArgs []string) (ApiAAAHandler, error) {

	apiAAA := ApiAAAHandler{}
	webservices := &pfconfigdriver.PfConfWebservices{}
	unifiedApiSystemUser := &pfconfigdriver.UnifiedApiSystemUser{}
	advanced := &pfconfigdriver.PfConfAdvanced{}
	adminLogin := &pfconfigdriver.PfConfAdminLogin{}
	servicesURL := &pfconfigdriver.PfConfServicesURL{}

	pfconfigdriver.UpdateConfigStore(ctx, func(ctx context.Context, u *pfconfigdriver.ConfigStoreUpdater) {
		u.AddStruct(ctx, "PfConfWebservices", webservices)
		u.AddStruct(ctx, "UnifiedApiSystemUser", unifiedApiSystemUser)
		u.AddStruct(ctx, "PfConfAdvanced", advanced)
		u.AddStruct(ctx, "PfConfAdminLogin", adminLogin)
		u.AddStruct(ctx, "PfConfServicesURL", servicesURL)
	})

	tokenBackend := aaa.MakeTokenBackend(ctx, tokenBackendArgs)
	apiAAA.authentication = aaa.NewTokenAuthenticationMiddleware(tokenBackend)

	// Backend for the system Unified API user
	if unifiedApiSystemUser.User != "" {
		apiAAA.systemBackend = aaa.NewMemAuthenticationBackend(
			map[string]string{},
			map[string]bool{"ALL": true},
		)
		apiAAA.systemBackend.SetUser(unifiedApiSystemUser.User, unifiedApiSystemUser.Pass)
		apiAAA.authentication.AddAuthenticationBackend(apiAAA.systemBackend)
	} else {
		panic("Unable to setup the system user authentication backend")
	}

	// Backend for the pf.conf webservices user
	apiAAA.webservicesBackend = aaa.NewMemAuthenticationBackend(
		map[string]string{},
		map[string]bool{"ALL": true},
	)
	apiAAA.authentication.AddAuthenticationBackend(apiAAA.webservicesBackend)

	if webservices.User != "" {
		apiAAA.webservicesBackend.SetUser(webservices.User, webservices.Pass)
	}

	// Backend for SSO
	if sharedutils.IsEnabled(adminLogin.SSOStatus) {
		url, err := url.Parse(fmt.Sprintf("%s%s", adminLogin.SSOBaseUrl, adminLogin.SSOAuthorizePath))
		sharedutils.CheckError(err)
		apiAAA.authentication.AddAuthenticationBackend(aaa.NewPortalAuthenticationBackend(ctx, url, false))
	}

	// Backend for username/password auth via the internal auth sources
	if sharedutils.IsEnabled(adminLogin.AllowUsernamePassword) {
		url, err := url.Parse(fmt.Sprintf("%s/api/v1/authentication/admin_authentication", servicesURL.PfperlApi))
		sharedutils.CheckError(err)
		apiAAA.authentication.AddAuthenticationBackend(aaa.NewPfAuthenticationBackend(ctx, url, false))
	}

	apiAAA.authorization = aaa.NewTokenAuthorizationMiddleware(tokenBackend)

	router := httprouter.New()
	router.POST("/api/v1/login", apiAAA.handleLogin)
	router.GET("/api/v1/token_info", apiAAA.handleTokenInfo)
	router.GET("/api/v1/sso_info", apiAAA.handleSSOInfo)

	apiAAA.router = router

	return apiAAA, nil
}

// Handle an API login
func (h ApiAAAHandler) handleLogin(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	ctx := r.Context()
	defer statsd.NewStatsDTiming(ctx).Send("api-aaa.login")

	var loginParams struct {
		Username string
		Password string
	}

	err := json.NewDecoder(r.Body).Decode(&loginParams)

	if err != nil {
		msg := fmt.Sprintf("Error while decoding payload: %s", err)
		log.LoggerWContext(ctx).Error(msg)
		http.Error(w, fmt.Sprint(err), http.StatusBadRequest)
		return
	}

	auth, token, err := h.authentication.Login(ctx, loginParams.Username, loginParams.Password)

	if auth {
		w.WriteHeader(http.StatusOK)
		res, _ := json.Marshal(map[string]string{
			"token": token,
		})
		fmt.Fprintf(w, string(res))
	} else {
		w.WriteHeader(http.StatusUnauthorized)
		res, _ := json.Marshal(map[string]string{
			"message": err.Error(),
		})
		fmt.Fprintf(w, string(res))
	}
}

// Handle getting the token info
func (h ApiAAAHandler) handleTokenInfo(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	ctx := r.Context()
	defer statsd.NewStatsDTiming(ctx).Send("api-aaa.token_info")

	if r.URL.Query().Get("no-expiration-extension") == "" {
		h.authentication.TouchTokenInfo(ctx, r)
	}
	info, expiration := h.authorization.GetTokenInfoFromBearerRequest(ctx, r)

	if info != nil {
		// We'll want to render the roles as an array, not as a map
		prettyInfo := PrettyTokenInfo{
			AdminActions: make([]string, len(info.AdminActions(ctx))),
			AdminRoles:   make([]string, len(info.AdminRoles)),
			Username:     info.Username,
			ExpiresAt:    expiration,
		}

		i := 0
		for r, _ := range info.AdminActions(ctx) {
			prettyInfo.AdminActions[i] = r
			i++
		}

		i = 0
		for r, _ := range info.AdminRoles {
			prettyInfo.AdminRoles[i] = r
			i++
		}

		w.WriteHeader(http.StatusOK)
		res, _ := json.Marshal(map[string]interface{}{
			"item": prettyInfo,
		})
		fmt.Fprintf(w, string(res))
	} else {
		w.WriteHeader(http.StatusNotFound)
		res, _ := json.Marshal(map[string]string{
			"message": "Couldn't find any information for the current token. Either it is invalid or it has expired.",
		})
		fmt.Fprintf(w, string(res))
	}
}

func (h ApiAAAHandler) handleSSOInfo(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	adminLogin := pfconfigdriver.GetStruct(r.Context(), "PfConfAdminLogin").(*pfconfigdriver.PfConfAdminLogin)
	info := struct {
		LoginText string `json:"login_text"`
		LoginURL  string `json:"login_url"`
		IsEnabled bool   `json:"is_enabled"`
	}{
		LoginText: adminLogin.SSOLoginText,
		LoginURL:  fmt.Sprintf("%s%s", adminLogin.SSOBaseUrl, adminLogin.SSOLoginPath),
		IsEnabled: sharedutils.IsEnabled(adminLogin.SSOStatus),
	}

	json.NewEncoder(w).Encode(info)
}

func (h ApiAAAHandler) HandleAAA(w http.ResponseWriter, r *http.Request) bool {
	if aaa.IsPathPublic(r.URL.Path) {
		return true
	}

	ctx := r.Context()
	auth, err := h.authentication.BearerRequestIsAuthorized(ctx, r)

	if !auth {
		w.WriteHeader(http.StatusUnauthorized)

		if err == nil {
			err = errors.New("Invalid token. Login again using /api/v1/login")
		}

		res, _ := json.Marshal(map[string]string{
			"message": err.Error(),
		})
		fmt.Fprintf(w, string(res))
		return false
	}

	h.authentication.TouchTokenInfo(ctx, r)

	auth, err = h.authorization.BearerRequestIsAuthorized(ctx, r)

	if auth {
		return true
	} else {
		if err.Error() == aaa.InvalidTokenInfoErr {
			w.WriteHeader(http.StatusUnauthorized)
		} else {
			w.WriteHeader(http.StatusForbidden)
		}
		res, _ := json.Marshal(map[string]string{
			"message": err.Error(),
		})
		fmt.Fprintf(w, string(res))
		return false
	}
}

func (h ApiAAAHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) (int, error) {
	ctx := r.Context()
	webservices := pfconfigdriver.GetStruct(ctx, "PfConfWebservices").(*pfconfigdriver.PfConfWebservices)
	// Reload the webservices user info
	if webservices.User != "" {
		h.webservicesBackend.SetUser(webservices.User, webservices.Pass)
	}

	defer panichandler.Http(ctx, w)

	defer func() {
		// We default to application/json if there is no content type
		if w.Header().Get("Content-Type") == "" {
			w.Header().Set("Content-Type", "application/json")
		}
	}()

	if handle, params, _ := h.router.Lookup(r.Method, r.URL.Path); handle != nil {
		handle(w, r, params)

		// TODO change me and wrap actions into something that handles server errors
		return 0, nil
	} else {
		_, noauth := h.noAuthPaths[r.URL.Path]
		if noauth || h.HandleAAA(w, r) {
			code, err := h.Next.ServeHTTP(w, r)

			return code, err

		} else {
			// TODO change me and wrap actions into something that handles server errors
			return 0, nil
		}
	}

}
