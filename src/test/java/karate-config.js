function fn() {
  var env = karate.env; // valor pasado con -Dkarate.env=xxx (opcional, default 'dev')
  if (!env) {
    env = 'dev';
  }
  karate.log('karate.env ->', env);

  var config = {
    env: env,
    baseUrl: 'https://fakestoreapi.com'
  };

  if (env === 'dev') {
    // unico ambiente disponible para este reto: la API publica de fakestoreapi.com
  }

  // timeouts globales de conexion/lectura (ms) para no dejar la suite colgada
  // si la API publica (compartida por terceros) responde lento o no responde.
  karate.configure('connectTimeout', 10000);
  karate.configure('readTimeout', 10000);

  // loguea siempre request/response completos (URL, headers, body) para trazabilidad
  // en el reporte, tal como exige el entregable "Reporte de ejecucion".
  karate.configure('logPrettyRequest', true);
  karate.configure('logPrettyResponse', true);

  return config;
}
