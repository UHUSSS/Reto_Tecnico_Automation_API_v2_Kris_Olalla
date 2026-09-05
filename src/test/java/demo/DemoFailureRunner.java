package demo;

import com.intuit.karate.Runner;
import org.junit.jupiter.api.Test;

/**
 * Runner aislado, solo para generar (bajo demanda) la evidencia de reporte de fallo exigida
 * en el entregable 7.2. No se incluye en el `mvn test` por defecto (ver pom.xml, surefire solo
 * incluye TestRunner.java), por lo que jamas rompe la suite de regresion principal.
 *
 * Ejecutar explicitamente con: mvn test -Dtest=DemoFailureRunner
 */
class DemoFailureRunner {

    @Test
    void demoFailure() {
        // sin assertTrue sobre el resultado: el objetivo es que Karate escriba el reporte
        // HTML/JSON del fallo en target/karate-reports, no hacer fallar este build.
        Runner.path("classpath:demo").parallel(1);
    }
}
