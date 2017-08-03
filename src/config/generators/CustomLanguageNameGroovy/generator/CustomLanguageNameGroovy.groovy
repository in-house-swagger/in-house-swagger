@Grab('io.swagger:swagger-codegen-cli:2.1.4')
import io.swagger.codegen.*;
import io.swagger.codegen.languages.*;

class CustomLanguageNameGroovy extends AbstractTypeScriptClientCodegen {

  String name = "my-typescript"
  String help = "Custom Typescript code generator"

  CustomLanguageNameGroovy() {
    super()
    this.modelTemplateFiles["model.mustache"] = ".ts"
    this.apiTemplateFiles["api.mustache"] = ".ts"
    this.apiPackage = "API.Client"
    this.modelPackage = "API.Client"
    this.supportingFiles.add(new SupportingFile("api.d.mustache", apiPackage().replaceAll(/\./, "${File.separatorChar}"), "api.d.ts"))

    // 型変換のoverride
    this.typeMapping.DateTime = "string";
  }

  // CLIへののkick
  public static main(String[] args) {
    SwaggerCodegen.main(args)
  }

}
