# reservepay-csharp

Typed C# clients to allow usage of the Reservepay APIs - [Merchant](https://developer.reservepay.com/api/merchants), [SDK](https://developer.reservepay.com/api/sdk)
, and [Terminal](https://developer.reservepay.com/api/terminals).

The clients (found in `src/Reservepay/`) were generated using the [WebFunction CLI tool](https://github.com/webfunction-protocol/webfunction-cli).

## Usage

```
dotnet add package Reservepay
```

Each API is in its own namespace (`Reservepay.Merchant`, `Reservepay.SDK`, `Reservepay.Terminal`), each with a `Client` class. Each `Client` has a static `NewClientAsync` method which returns a fully configured client, ready to access the associated API.

```csharp
using Reservepay.Merchant;

var client = await Client.NewClientAsync(bearerAuth: "MY_API_KEY");

var versions = await client.AvailableApiVersions();

Console.WriteLine(string.Join(", ", versions));
```

To use more than one API in the same file, alias the clients:

```csharp
using MerchantClient = Reservepay.Merchant.Client;
using TerminalClient = Reservepay.Terminal.Client;
```

The clients wrap [webfunction-csharp](https://github.com/webfunction-protocol/webfunction-csharp), which is installed as a dependency.

## Regenerating the clients

`./refresh_clients.sh` regenerates all three clients from the live APIs. It needs the `wfn` tool (set `WFN_PATH` if it is not in your `PATH`).
