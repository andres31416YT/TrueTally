# Tarea: Integrar SonarQube en el pipeline del proyecto (Curso IaC)

## Contexto importante (leer antes de hacer nada)

Al final de este documento hay un **anexo con una guía de referencia conceptual sobre SonarQube con Docker** (qué es, cómo se instala, cómo se configura el análisis, cómo se integra en CI/CD). Es material genérico de apoyo, **no un instructivo que debas copiar literal**. Nuestro proyecto NO es el mismo que el del ejemplo de esa guía, así que:

- **NO copies la estructura exacta de la guía** (nombres de carpetas, `project key` de ejemplo como `mi-proyecto`, rutas como `src`, nombres de contenedores genéricos, etc.)
- **NO asumas que nuestro proyecto usa SonarScanner CLI genérico** si en realidad es Maven, Gradle, .NET, Node, Python, etc. Hay que detectar qué stack usa nuestro proyecto real y usar el scanner correcto (la guía tiene una tabla de referencia para esto).
- **SÍ debes adaptar los conceptos** (Docker Compose con Postgres, generación de token, `sonar-project.properties`, integración en CI/CD) a la estructura real de nuestro repo.
- El objetivo final son **2 entregables visuales (capturas de pantalla)** que el alumno (yo) voy a tomar manualmente, no el asistente. El asistente debe dejar todo funcionando para que esas capturas se puedan tomar.

## Qué se pide exactamente

Hay que evidenciar con capturas de pantalla:

1. **Configuración en el Pipeline** → o sea, el step/job de CI/CD (GitHub Actions en nuestro caso) que ejecuta el análisis de SonarQube contra nuestro proyecto.
2. **Estado del proyecto actual** → el dashboard de SonarQube mostrando el resultado del análisis (Quality Gate, bugs, vulnerabilidades, code smells, coverage, duplications, etc. — ver la sección "Interpretar los resultados" del anexo).

Plazo: **1 semana**.

## Lo que necesito que hagas (asistente)

### 1. Detectar el stack real del proyecto
Antes de tocar nada, revisa el repositorio actual y determina:
- Lenguaje/framework (Java+Maven, Java+Gradle, .NET, Node/TS/JS, Python, Go, etc.)
- Si ya existe un `docker-compose.yml`, pipeline de GitHub Actions, o algo de IaC ya armado (Terraform, etc.) que ya usamos en el curso, para no romper nada existente.
- Estructura de carpetas real (dónde está el código fuente, tests, etc.)

No asumas nada del anexo como verdad para nuestro caso — verifícalo contra el repo real.

### 2. Levantar SonarQube localmente (para pruebas, no es lo que se evidencia en la captura final del pipeline, pero sirve para validar antes de subir a CI)

Usa Docker Compose con PostgreSQL (ver "Opción B" en el anexo), **pero adapta los nombres de servicios/volúmenes al nombre de nuestro proyecto** en vez de copiar literal `sonarqube`, `sonarqube_db`, etc. si ya tenemos convenciones de nombres en el curso.

Verifica también si hace falta el ajuste de kernel en Linux (`vm.max_map_count`, ver "Requisitos previos" en el anexo) según el entorno donde se vaya a correr.

### 3. Generar el token de análisis
Sigue la lógica de "Generar un token de análisis" en el anexo (token vía la web de SonarQube, en *My Account → Security → Generate Tokens*). Este token **debe guardarse como secret del pipeline** (GitHub Actions secrets), nunca hardcodeado en el repo ni en el `sonar-project.properties`.

### 4. Crear el proyecto en SonarQube
Crear el proyecto con un `Project key` que tenga sentido para **nuestro proyecto real** (no "mi-proyecto"). Usa un nombre descriptivo y consistente con el resto de nuestra infraestructura (mismo naming que usamos en Terraform/AWS si aplica).

### 5. Configurar el análisis según el scanner correcto
Mira la tabla "Elegir el scanner adecuado" en el anexo y elige el scanner que corresponde a nuestro stack real:
- Si es genérico (JS/TS/Python/Go/PHP) → SonarScanner CLI + archivo `sonar-project.properties`, pero con `sonar.sources` apuntando a la carpeta real de nuestro código, no a `src` si no se llama así.
- Si es Java con Maven → usar el plugin de Maven, no el CLI genérico.
- Si es Java con Gradle → plugin de Gradle.
- Si es .NET → `dotnet-sonarscanner`.

**No mezcles métodos.** Usa solo el que corresponde a nuestro proyecto.

### 6. Integrar el análisis en el pipeline de CI/CD (esto es lo que se va a capturar como "Configuración en Pipeline")

Esto es el corazón de la tarea. Como ya usamos GitHub Actions en el curso (con OIDC + IAM roles para AWS), agrega un **job o step nuevo** dentro de nuestro workflow existente (o uno nuevo si tiene más sentido) que:

1. Tenga acceso al `SONAR_TOKEN` y `SONAR_HOST_URL` como **GitHub Secrets** (nunca en texto plano).
2. Ejecute el scanner correspondiente a nuestro stack.
3. Opcionalmente, falle el pipeline si el Quality Gate no pasa (esto es lo recomendado en el anexo — "que la integración falle si el código no aprueba").

Importante: el anexo da el patrón general pero no un YAML específico de GitHub Actions — tenemos que armarlo nosotros basándonos en nuestro proyecto real y en cómo ya estructuramos los demás workflows del curso (Terraform, Checkov, etc.), para que se vea consistente con el resto del repo y no como algo pegado de otro lado.

### 7. Verificar que el análisis corra y se vea bien en el dashboard

Corre el pipeline (push o PR de prueba) y confirma que:
- El step de SonarQube se ejecuta sin errores.
- En el dashboard de SonarQube aparece el proyecto con su Quality Gate, bugs, vulnerabilidades, code smells, etc. (ver "Interpretar los resultados" en el anexo).

Esto es lo que yo voy a capturar manualmente como evidencia de "Estado de proyecto actual".

### 8. Troubleshooting
Si algo falla, revisa "Solución de problemas comunes" en el anexo (errores comunes: `vm.max_map_count`, conexión `localhost` vs `host.docker.internal`, error 401 por token inválido, etc.) antes de asumir que es otro problema.

## Resumen de lo que NO debe pasar

- No copiar/pegar el `docker-compose.yml` de ejemplo del anexo tal cual con nombres genéricos.
- No usar `mi-proyecto` como project key.
- No asumir SonarScanner CLI si el proyecto es Maven/Gradle/.NET.
- No hardcodear el token en ningún archivo del repo.
- No crear una estructura de pipeline desconectada del resto de nuestros workflows existentes en el curso.

## Resultado esperado al final

1. SonarQube corriendo (local o en algún entorno accesible) con nuestro proyecto creado.
2. Un step/job en el pipeline de GitHub Actions que ejecuta el análisis automáticamente.
3. El dashboard de SonarQube mostrando resultados reales de nuestro código (no de un proyecto de ejemplo).
4. Todo listo para que yo tome las 2 capturas: configuración del pipeline + estado del proyecto.

---

## Anexo: Guía de referencia conceptual sobre SonarQube con Docker

> Material de apoyo general. Recordatorio: **no replicar literal**, usar solo como referencia conceptual y adaptar todo al proyecto real (ver instrucciones arriba).

### ¿Qué es SonarQube?

SonarQube es una plataforma de código abierto para la inspección continua de la calidad y la seguridad del código. Analiza el código fuente de un proyecto y detecta automáticamente tres grandes tipos de problemas: defectos (bugs), olores de código (code smells, es decir, malas prácticas que dificultan el mantenimiento) y vulnerabilidades de seguridad. Además mide la cobertura de pruebas y la duplicación de código.

El resultado se presenta en un panel web donde cada proyecto recibe una valoración objetiva. En lugar de revisar la calidad "a ojo", el equipo trabaja con métricas reproducibles y con una puerta de calidad (Quality Gate) que decide si el código cumple o no con los estándares acordados.

#### Conceptos clave

| Concepto | Qué significa |
|---|---|
| Proyecto | Unidad de análisis en SonarQube. Normalmente equivale a un repositorio o a una aplicación. |
| Quality Profile | Conjunto de reglas que se aplican al analizar (qué se considera bug, smell, etc.). Hay uno por lenguaje. |
| Quality Gate | Conjunto de condiciones que el código debe cumplir para considerarse "aprobado" (por ejemplo: 0 bugs nuevos, cobertura > 80%). |
| Issue | Cada problema concreto detectado, con su severidad y ubicación en el código. |
| Scanner | Programa que recorre el código, lo analiza y envía los resultados al servidor de SonarQube. |
| Token | Credencial que usa el scanner para autenticarse contra el servidor sin exponer usuario y contraseña. |

#### ¿Por qué SonarQube en un curso de IaC?

En Infraestructura como Código toda la plataforma se describe en archivos versionables y reproducibles. SonarQube encaja en esa filosofía por dos motivos:

- Se despliega como infraestructura declarativa. En lugar de instalarlo manualmente, se levanta con Docker y un archivo `docker-compose.yml` que cualquiera puede recrear con un solo comando.
- Lleva la calidad al pipeline. El mismo análisis que se ejecuta en una máquina local se integra después en CI/CD, de modo que la calidad del código se verifica de forma automática y consistente, igual que se valida la infraestructura.

Idea clave: el archivo de Docker Compose ES la infraestructura como código. Quien lo tenga puede reproducir exactamente el mismo entorno de SonarQube.

### Requisitos previos

Antes de empezar, hace falta contar con lo siguiente:

- Docker Engine 20.10 o superior y Docker Compose instalados. SonarQube funciona en amd64 y en arm64 (Apple Silicon).
- Memoria RAM: mínimo recomendado 4 GB libres. SonarQube usa internamente Elasticsearch, que es exigente con la memoria.
- Acceso a una terminal y conocimientos básicos de línea de comandos.
- El proyecto de código ya existente en una carpeta local (es lo que se va a analizar).

Comprobar que Docker está disponible ejecutando:

```
docker --version
docker compose version
```

**Linux — paso importante:** Elasticsearch (incluido en SonarQube) exige aumentar un parámetro del kernel.

```
sudo sysctl -w vm.max_map_count=524288
sudo sysctl -w fs.file-max=131072
```

Para que persista tras reiniciar, hay que añadir `vm.max_map_count=524288` al archivo `/etc/sysctl.conf`. En Windows o macOS con Docker Desktop normalmente no es necesario.

### Visión general de la solución

Se levantan dos contenedores que trabajan juntos:

| Contenedor | Rol |
|---|---|
| sonarqube | El servidor: interfaz web (puerto 9000), motor de análisis y reglas. |
| db (PostgreSQL) | La base de datos donde SonarQube guarda proyectos, métricas e históricos. |

Por defecto SonarQube usa una base de datos interna pensada solo para pruebas. Usar PostgreSQL desde el inicio es la práctica correcta: los datos persisten y el entorno se parece al de producción.

El flujo de trabajo completo es:

1. Levantar SonarQube + PostgreSQL con Docker Compose.
2. Entrar a la web, cambiar la contraseña y generar un token.
3. Crear el proyecto y describir el análisis con `sonar-project.properties`.
4. Ejecutar el SonarScanner sobre el código.
5. Revisar los resultados y el Quality Gate en la web.

### Instalación con Docker

#### Opción A — Arranque rápido (un solo comando)

```
docker run -d --name sonarqube -p 9000:9000 sonarqube:community
```

Esto descarga la imagen `sonarqube:community`, crea el contenedor y publica la web en el puerto 9000. Pasados unos minutos estará disponible en `http://localhost:9000`.

#### Opción B — Docker Compose con PostgreSQL (recomendada)

Crear una carpeta para el entorno (ejemplo: `sonarqube-lab`) y dentro un archivo llamado `docker-compose.yml` con este contenido (de referencia, hay que ajustar nombres al proyecto real):

```yaml
services:
  sonarqube:
    image: sonarqube:community
    container_name: sonarqube
    depends_on:
      - db
    ports:
      - "9000:9000"
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonarqube
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
    restart: unless-stopped
  db:
    image: postgres:16
    container_name: sonarqube_db
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
      POSTGRES_DB: sonarqube
    volumes:
      - postgresql_data:/var/lib/postgresql/data
    restart: unless-stopped
volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
  postgresql_data:
```

Lo más importante de este archivo, el corazón de la parte IaC:

- `services`: se declaran los dos contenedores (sonarqube y db).
- `environment`: las variables que conectan SonarQube con PostgreSQL. El host es `db`, el nombre del servicio dentro de la red de Compose.
- `volumes`: volúmenes nombrados para que los datos, extensiones, logs y la base de datos sobrevivan a reinicios y actualizaciones.
- `restart: unless-stopped`: vuelve a levantar los contenedores si la máquina se reinicia.

Sobre las versiones: el tag `sonarqube:community` entrega siempre la última Community Build. Si se prefiere una versión estable de largo soporte (LTA), se puede cambiar el tag por `sonarqube:2026-lta-community`.

##### Levantar el entorno

Desde la carpeta donde está el `docker-compose.yml`, ejecutar:

```
docker compose up -d
```

La opción `-d` lo deja corriendo en segundo plano. Para ver el progreso de arranque y comprobar que no hay errores:

```
docker compose logs -f sonarqube
```

Hay que buscar en los logs una línea similar a "SonarQube is operational". Cuando aparezca, el servidor está listo. El primer arranque puede tardar varios minutos.

##### Comandos básicos de gestión

| Acción | Comando |
|---|---|
| Ver estado de los contenedores | `docker compose ps` |
| Detener el entorno (conserva datos) | `docker compose stop` |
| Apagar y borrar contenedores (conserva volúmenes) | `docker compose down` |
| Apagar y borrar TODO, incluidos datos | `docker compose down -v` |
| Reiniciar | `docker compose restart` |

Cuidado: el flag `-v` en `docker compose down -v` elimina los volúmenes y, con ellos, todos los proyectos y resultados. Usarlo solo cuando se quiera empezar de cero.

### Primer acceso y configuración inicial

1. Abrir el navegador en `http://localhost:9000`.
2. Iniciar sesión con las credenciales por defecto: usuario `admin` y contraseña `admin`.
3. SonarQube obligará a establecer una contraseña nueva. Hacerlo de inmediato: es la primera medida de seguridad.

#### Generar un token de análisis

El scanner necesita autenticarse. En lugar de usar la contraseña, se usa un token. Para crearlo:

1. Hacer clic en el avatar (arriba a la derecha) → My Account.
2. Entrar en la pestaña Security.
3. En Generate Tokens, escribir un nombre, elegir el tipo Global Analysis Token y pulsar Generate.
4. Copiar el token y guardarlo en un lugar seguro: solo se muestra una vez.

Buena práctica: nunca escribir el token directamente en el código ni subirlo al repositorio. Guardarlo en una variable de entorno o en un gestor de secretos.

### Configurar el análisis de un proyecto

#### Crear el proyecto en SonarQube

1. En la web, ir a Projects → Create Project → Local project.
2. Indicar un Project key (identificador único) y un nombre visible.
3. Elegir analizar la rama principal con su nombre real (normalmente `main`).
4. Cuando pregunte el método de análisis, seleccionar Locally. SonarQube mostrará un ejemplo de comando ya con el project key correspondiente.

#### Elegir el scanner adecuado

El scanner depende de la tecnología del proyecto. Estos son los más comunes:

| Tipo de proyecto | Scanner recomendado |
|---|---|
| Genérico (JS, TS, Python, Go, PHP, etc.) | SonarScanner CLI |
| Java/Kotlin con Maven | Plugin sonar de Maven |
| Java/Kotlin con Gradle | Plugin SonarQube de Gradle |
| .NET (C#, VB.NET) | SonarScanner for .NET |

#### El archivo sonar-project.properties

Para el SonarScanner CLI, la configuración del análisis se describe en un archivo llamado `sonar-project.properties`, ubicado en la raíz del proyecto. Es, de nuevo, configuración como código. Un ejemplo típico:

```
# Identificador del proyecto (debe coincidir con el Project key)
sonar.projectKey=mi-proyecto
sonar.projectName=Mi Proyecto
sonar.projectVersion=1.0

# Dónde está el código fuente (relativo a este archivo)
sonar.sources=src

# Codificación de los archivos
sonar.sourceEncoding=UTF-8

# URL del servidor SonarQube
sonar.host.url=http://localhost:9000
```

Hay que ajustar `sonar.sources` a la carpeta real del código (por ejemplo `.` para todo el proyecto, o `src`).

#### Ejecutar el análisis con SonarScanner CLI

No hace falta instalar nada en la máquina: existe una imagen oficial del scanner en Docker. Desde la raíz del proyecto, ejecutar (Linux/macOS):

```
docker run --rm \
  -e SONAR_HOST_URL="http://localhost:9000" \
  -e SONAR_TOKEN="TU_TOKEN_AQUI" \
  -v "$(pwd):/usr/src" \
  --network host \
  sonarsource/sonar-scanner-cli
```

En Windows (PowerShell), reemplazar `$(pwd)` por `${PWD}` y quitar las barras de continuación `\`, escribiendo el comando en una sola línea.

Sobre `--network host`: permite que el contenedor del scanner vea `localhost:9000`. En Docker Desktop (Windows/macOS) puede no funcionar; en ese caso usar `http://host.docker.internal:9000` como `SONAR_HOST_URL` y eliminar `--network host`.

Cuando el análisis termine, se verá en la salida un mensaje "ANALYSIS SUCCESSFUL" con un enlace al panel del proyecto.

#### Variantes según el proyecto

**Maven**

Si el proyecto usa Maven, no se necesita `sonar-project.properties`. Ejecutar desde la raíz:

```
mvn clean verify sonar:sonar \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=TU_TOKEN_AQUI \
  -Dsonar.projectKey=mi-proyecto
```

**Gradle**

Añadir el plugin en el `build.gradle` (`id "org.sonarqube" version "..."`) y ejecutar:

```
./gradlew sonar \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=TU_TOKEN_AQUI \
  -Dsonar.projectKey=mi-proyecto
```

**.NET**

Con la herramienta `dotnet-sonarscanner`, el análisis envuelve a la compilación:

```
dotnet sonarscanner begin /k:"mi-proyecto" \
  /d:sonar.host.url="http://localhost:9000" \
  /d:sonar.token="TU_TOKEN_AQUI"
dotnet build
dotnet sonarscanner end /d:sonar.token="TU_TOKEN_AQUI"
```

### Interpretar los resultados

En la página del proyecto se encuentra un resumen con las métricas principales:

| Métrica | Qué indica |
|---|---|
| Quality Gate | Aprobado (Passed) o fallido (Failed). Es el veredicto general. |
| Bugs / Reliability | Errores que pueden provocar comportamiento incorrecto. |
| Vulnerabilities / Security | Debilidades explotables desde el punto de vista de seguridad. |
| Security Hotspots | Zonas sensibles que conviene revisar manualmente. |
| Code Smells / Maintainability | Malas prácticas que dificultan el mantenimiento (deuda técnica). |
| Coverage | Porcentaje de código cubierto por pruebas (si se envía el informe de cobertura). |
| Duplications | Porcentaje de código duplicado. |

Por defecto, el Quality Gate "Sonar way" se centra en el código nuevo (lo que se ha cambiado desde el último análisis). Es una decisión deliberada: en lugar de arreglar todo el histórico de golpe, se mantiene limpio lo nuevo y se mejora de forma incremental. Haciendo clic en cualquier issue se puede ver el archivo, la línea exacta, la regla que se incumple y una explicación de cómo corregirlo.

### Siguiente paso: llevarlo al pipeline

El verdadero valor en IaC aparece cuando el análisis deja de ser manual. La idea es ejecutar el mismo scanner dentro del pipeline de CI/CD, de forma que cada cambio se analice automáticamente y el Quality Gate pueda bloquear una integración que no cumpla la calidad mínima. La configuración varía según la herramienta (GitHub Actions, GitLab CI, Jenkins…), pero el patrón es siempre el mismo:

1. Guardar la URL del servidor y el token como secretos del pipeline.
2. Añadir un paso que ejecute el SonarScanner correspondiente.
3. Configurar la verificación del Quality Gate para que la integración falle si el código no aprueba.

### Solución de problemas comunes

| Síntoma | Causa y solución |
|---|---|
| El contenedor se reinicia o no arranca (Linux) | Falta subir `vm.max_map_count`. Aplicar el sysctl correspondiente y volver a levantar. |
| La web no carga en localhost:9000 | Aún está arrancando. Revisar `docker compose logs -f sonarqube` y esperar a "operational". |
| El scanner no conecta con el servidor | Problema de red. En Docker Desktop usar `host.docker.internal` en vez de `localhost`. |
| Error 401 / Unauthorized al analizar | Token inválido o ausente. Regenerar el token y pasarlo en `SONAR_TOKEN`. |
| No aparece cobertura de pruebas | Hay que generar el informe con la herramienta de test y apuntar a él con la propiedad de cobertura adecuada. |
| Se olvidó la contraseña de admin | Si es un entorno de pruebas, lo más rápido es recrear con `docker compose down -v` y empezar de cero. |

### Comandos de referencia rápida

```
# Levantar SonarQube + PostgreSQL
docker compose up -d

# Ver logs del servidor
docker compose logs -f sonarqube

# Analizar (SonarScanner CLI, desde la raíz del proyecto)
docker run --rm \
  -e SONAR_HOST_URL="http://localhost:9000" \
  -e SONAR_TOKEN="TU_TOKEN_AQUI" \
  -v "$(pwd):/usr/src" \
  --network host \
  sonarsource/sonar-scanner-cli

# Apagar (conservando datos)
docker compose stop
```

Documentación oficial para profundizar: https://docs.sonarsource.com/sonarqube-community-build/