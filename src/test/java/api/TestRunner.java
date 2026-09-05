package api;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import net.masterthought.cucumber.Configuration;
import net.masterthought.cucumber.ReportBuilder;
import org.junit.jupiter.api.Test;

import java.io.File;
import java.io.FilenameFilter;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Runner unico de la suite completa. Ejecuta todos los .feature bajo src/test/java/api,
 * genera el reporte nativo de Karate (cucumber-json + karate-summary.html) y, a partir
 * de esos mismos cucumber-json (uno por feature), un reporte HTML enriquecido (masterthought)
 * con el detalle de request/response por escenario que exige el entregable de reporteria del reto.
 */
class TestRunner {

    @Test
    void testParallel() {
        Results results = Runner.path("classpath:api")
                .outputCucumberJson(true)
                .parallel(5);

        generateMasterthoughtReport(results.getReportDir());

        assertTrue(results.getFailCount() == 0, results.getErrorMessages());
    }

    private static void generateMasterthoughtReport(String karateOutputPath) {
        File karateReportsDir = new File(karateOutputPath);
        FilenameFilter cucumberJsonFilter = (dir, name) -> name.endsWith(".json");
        File[] jsonFiles = karateReportsDir.listFiles(cucumberJsonFilter);

        List<String> jsonPaths = new ArrayList<>();
        if (jsonFiles != null) {
            for (File jsonFile : jsonFiles) {
                jsonPaths.add(jsonFile.getAbsolutePath());
            }
        }

        // Configuration ya agrega el subdirectorio "cucumber-html-reports"; se pasa "target"
        // como raiz para que el resultado quede en target/cucumber-html-reports/ (un solo nivel).
        File reportOutputDirectory = new File("target");
        Configuration config = new Configuration(reportOutputDirectory, "Fake Store API - Automation Suite");
        ReportBuilder reportBuilder = new ReportBuilder(jsonPaths, config);
        reportBuilder.generateReports();
    }
}
