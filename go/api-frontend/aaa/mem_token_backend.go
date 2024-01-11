package aaa

import (
	"context"
	"time"

	cache "github.com/patrickmn/go-cache"
)

type MemTokenBackend struct {
	store         *cache.Cache
	maxExpiration time.Duration
}

func NewMemTokenBackend(expiration time.Duration, maxExpiration time.Duration, args []string) TokenBackend {
	return &MemTokenBackend{
		store:         cache.New(expiration, 10*time.Minute),
		maxExpiration: maxExpiration,
	}
}

func (tb *MemTokenBackend) Type() string {
	return "mem"
}

func (mtb *MemTokenBackend) TokenIsValid(token string) bool {
	_, found := mtb.store.Get(token)
	return found
}

func (mtb *MemTokenBackend) TokenInfoForToken(token string) (*TokenInfo, time.Time) {
	if o, expiration, found := mtb.store.GetWithExpiration(token); found {
		if ti, ok := o.(*TokenInfo); ok {
			return ValidTokenExpiration(ti, expiration, mtb.maxExpiration)
		}
	}

	return nil, time.Unix(0, 0)
}

func (mtb *MemTokenBackend) AdminActionsForToken(ctx context.Context, token string) map[string]bool {
	if ti, _ := mtb.TokenInfoForToken(token); ti != nil {
		return ti.AdminActions(ctx)
	} else {
		return make(map[string]bool)
	}
}

func (mtb *MemTokenBackend) StoreTokenInfo(token string, ti *TokenInfo) error {
	ti.CreatedAt = time.Now()
	mtb.store.SetDefault(token, ti)
	return nil
}

func (mtb *MemTokenBackend) TouchTokenInfo(token string) {
	if ti, _ := mtb.TokenInfoForToken(token); ti != nil {
		mtb.store.SetDefault(token, ti)
	}
}

var _ TokenBackend = (*MemTokenBackend)(nil)
