# Dockerfile worker

FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /app
COPY . ./
RUN dotnet restore
RUN dotnet publish -c release --self-contained false --no-restore
FROM mcr.microsoft.com/dotnet/runtime:7.0 AS build2
WORKDIR /app
COPY --from=build /app/bin/release/net7.0 ./
CMD ["dotnet", "Worker.dll"]

