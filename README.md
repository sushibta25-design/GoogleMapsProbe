# GoogleMapsProbe
Read-only probe injected only into `com.google.Maps`.

## Test
1. Install rootless DEB, respring.
2. Open Google Maps.
3. Search exactly: `canh cá rô đồng`.
4. Open 2-3 results, wait ~5 seconds each.
5. Send `/var/mobile/GoogleMapsProbe.log`.

V0.1 intentionally limits logging. It observes JSON/runtime objects and NSURLSession responses containing search-related terms; it does not modify Google Maps or replay private endpoints.
