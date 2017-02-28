package pfconfigdriver

import (
	"context"
	//"github.com/davecgh/go-spew/spew"
	"fmt"
	"github.com/fingerbank/processor/log"
	"os"
	"time"
)

// The global resource pool that can be used to keep track of loaded resources
var GlobalPfconfigResourcePool *ResourcePool

func init() {
	GlobalPfconfigResourcePool = NewResourcePool(context.Background())
}

type Resource struct {
	namespace string
	query     Query
	loadedAt  time.Time
}

// The path to the control file of the resource
func (r *Resource) controlFile() string {
	return "/usr/local/pf/var/control/" + r.namespace + "-control"
}

// Whether or not a resource is valid
// To be valid, the control file must exist and the loadedAt value must be higher than the control file timestamp
func (r *Resource) IsValid(ctx context.Context) bool {
	ctx = log.AddToLogContext(ctx, "PfconfigObject", r.query.GetIdentifier())
	stat, err := os.Stat(r.controlFile())

	if err != nil {
		log.LoggerWContext(ctx).Error(fmt.Sprintf("Cannot stat %s. Will consider resource as invalid"))
		return false
	} else {
		controlTime := stat.ModTime()
		if r.loadedAt.Before(controlTime) {
			log.LoggerWContext(ctx).Debug("Resource is not valid anymore.")
			return false
		} else {
			return true
		}
	}
}

type ResourcePool struct {
	//Map of loaded resource by type name
	loadedResources map[string]Resource
}

// Create a new ResourcePool
func NewResourcePool(ctx context.Context) *ResourcePool {
	return &ResourcePool{
		loadedResources: make(map[string]Resource),
	}
}

//Check whether or not a resource is valid in the pool using the pfconfig compatible struct
func (rp *ResourcePool) ResourceIsValid(ctx context.Context, o PfconfigObject) bool {
	res, ok := rp.FindResource(ctx, o)
	if ok {
		return res.IsValid(ctx)
	} else {
		return false
	}
}

// Find a resource by a pfconfig compatible struct
func (rp *ResourcePool) FindResource(ctx context.Context, o PfconfigObject) (Resource, bool) {
	query := createQuery(ctx, o)
	ctx = log.AddToLogContext(ctx, "PfconfigObject", query.GetIdentifier())

	log.LoggerWContext(ctx).Debug("Finding resource")
	res, ok := rp.loadedResources[query.GetIdentifier()]
	return res, ok
}

// Get the namespace for a given pfconfig resource
func (rp *ResourcePool) getNamespace(ctx context.Context, o PfconfigObject) string {
	return metadataFromField(ctx, o, "PfconfigNS")
}

// Loads a resource and loads it from the process loaded resources unless the resource has changed in pfconfig
// A previously loaded PfconfigObject can be send to this method. If its previously loaded, it will not be touched if the namespace hasn't changed in pfconfig. If its previously loaded and has changed in pfconfig, the new data will be put in the existing PfconfigObject. Should field be unset or have disapeared in pfconfig, it will be properly set back to the zero value of the field. See https://play.golang.org/p/_dYY4Qe5_- for an example. In order for this process to happen, firstLoad must be set to false. Otherwise the resource will be loaded from pfconfig
// Returns whether the resource has been loaded/reloaded from pfconfig or not
func (rp *ResourcePool) LoadResource(ctx context.Context, o PfconfigObject, firstLoad bool) (bool, error) {
	query := createQuery(ctx, o)
	namespace := rp.getNamespace(ctx, o)

	ctx = log.AddToLogContext(ctx, "PfconfigObject", query.GetIdentifier())

	log.LoggerWContext(ctx).Debug("Started resource loading")

	alreadyLoaded := false

	// If this PfconfigObject was already loaded and hasn't changed since the load, then we can safely return and leave the current config untouched
	if res, ok := rp.FindResource(ctx, o); ok {
		alreadyLoaded = true
		if !firstLoad {
			if res.IsValid(ctx) {
				return false, nil
			} else {
				// If its invalid, its not already loaded
				alreadyLoaded = false
			}
		}
	}

	// We don't want to put a newer version of the resource in the map since another older struct relies on it
	// The new one (current) can safely rely on the data in it even though it is older
	if !alreadyLoaded {
		rp.loadedResources[query.GetIdentifier()] = Resource{
			namespace: namespace,
			query:     query,
			loadedAt:  time.Now(),
		}
	}

	log.LoggerWContext(ctx).Info("Loading resource from pfconfig")
	err := FetchDecodeSocket(ctx, o)
	return true, err
}
