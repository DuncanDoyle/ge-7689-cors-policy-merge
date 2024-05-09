# Gloo-7689 Reproducer

Issue: https://github.com/solo-io/gloo/issues/7689

## Installation

Add Gloo EE Helm repo:
```
helm repo add glooe https://storage.googleapis.com/gloo-ee-helm
```

Export your Gloo Edge License Key to an environment variable:
```
export GLOO_EDGE_LICENSE_KEY={your license key}
```

Install Gloo Edge:
```
cd install
./install-gloo-edge-enterprise-with-helm.sh
```

> NOTE
> The Gloo Edge version that will be installed is set in a variable at the top of the `install/install-gloo-edge-enterprise-with-helm.sh` installation script.

## Setup the environment

Run the `install/setup.sh` script to setup the environment:

- Deploy the Perstore application
- Deploy the VirtualHostOption and RouteOption policies
- Deploy the VirtualServices

```
./setup.sh
```

## Call Petstore

Retrieve the Petstore OpenAPI spec/Swagger file:
```
curl -v http://petstore.example.com/swagger.json
```

Retrieve all pets:
```
curl -v http://petstore.example.com/api/pets
```

To get the CORS headers back, we need to send the "Origin" header with an origin that is in the CORS policiy's "allow-origin" list. Since the `VirtualService` references both the `VirtualHostOption` and `RouteOption`, the configuration in the `RouteOption` overrides the configuration in the `VirtualHostOption`. Hence, if we send the following request with `http://test.com` as the `Origin`, we will not get any CORS headers back as the configuration in the `VirtualHostOption` is overridden.
```
curl -vik -H "Origin: https://test.com" http://petstore.example.com/api/pets
```

However, if we send the same request, but now with `http://solo.io` as the `Origin`, we will see the CORS headers getting returned, as that URL is configured in the `allowOrigin` field of the `RouteOption`:

```
curl -vik -H "Origin: https://solo.io" http://petstore.example.com/api/pets
```

When we now apply the `VirtualService` that has no `RouteOption` configuration, we can see that the CORS configuration of the `VirtualHostOption` is applied, and the CORS headers are returned when we set the `Origin` to `http://test.com`:

```
kubectl apply -f virtualservices/petstore-example-com-vs-no-routeoption.yaml

curl -vik -H "Origin: https://test.com" http://petstore.example.com/api/pets
```





## Behaviour

Atm, the cors-policy defined on the route level (e.g via RouteOptions) overrides the policy defined on the VirtualService/VirtualHost level (e.g. via VirtualHostOptions).


## Questions

How do expect this functionality to work for the diffent CORS fields? And how should this be configured?

1. We can't break the current API and its current behaviour, as other users might rely on the fact that the RouteOptions override the VirtualHostOptions. Changing the "override" strategy into a "merge" strategy could potentially break environments, or make them vulnerable to security threads (Cross Site Request Forgery).

2. The above means that we either should specify a strategy in the:
  - the CRs of these resources
  - Gloo Edge Settings
  - ... somewhere else

3. Merge/override behaviour can be different for different fields:
  - If a field does not exist in a lower level config (e.g. RouteOption), we should probably merge the value from a higher level config (e.g. VirtualHostOption) if the strategy is set to "merge"
  - If a field is an array, we should probably merge the values of these 2 arrays when strategy is "merge".
  - If a field is a singular value, and the it's defined in both the higher level and lower level config .... and the strategy is "merge" ... what should the semantics be? .... Merging is impossible here ..... so it should probably be an override ..... ???

4. When using delegation principles (i.e. platform team defines VirtualServices with VirtualHostOptions and application teams define the RouteTable with RouteOptions), how do we deal with the fact that the platform team might want to restrict the "merge/override" strategies for these configurations (in particular because there can be security implications)?

5. How and where do we expose the final configuration of merged policies, so users can clearly see the actual policy configuratio that has been applied. We should not force users to look at the low-level Envoy configuration, so probably a "status" of some sort would be useful ...


## Conclusion
TODO