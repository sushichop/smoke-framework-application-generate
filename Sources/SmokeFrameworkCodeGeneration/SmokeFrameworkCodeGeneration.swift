// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//
//  ServiceModelCodeGenerator
//  SmokeFrameworkCodeGeneration
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities
import ServiceModelGenerate
import SmokeAWSModelGenerate

/**
 The supported generation types.
 */
public enum GenerationType: String {
    case server
    case serverUpdate = "serverupdate"
}

public struct SmokeFrameworkCodeGeneration {
    static let asyncResultType = AsyncResultType(typeName: "HTTPResult",
                                                 libraryImport: "SmokeHTTPClient")
    
    public static func generateFromModel<ModelType: ServiceModel>(
        modelFilePath: String,
        modelType: ModelType.Type,
        generationType: GenerationType,
        customizations: CodeGenerationCustomizations,
        applicationDescription: ApplicationDescription,
        modelOverride: ModelOverride?) throws {
            func generatorFunction(codeGenerator: ServiceModelCodeGenerator,
                                   serviceModel: ModelType) throws {
                try codeGenerator.generateFromModel(serviceModel: serviceModel, generationType: generationType)
            }
        
            try ServiceModelGenerate.generateFromModel(
                    modelFilePath: modelFilePath,
                    customizations: customizations,
                    applicationDescription: applicationDescription,
                    modelOverride: modelOverride,
                    generatorFunction: generatorFunction)
    }
}

extension ServiceModelCodeGenerator {
    
    func generateFromModel<ModelType: ServiceModel>(serviceModel: ModelType,
                                                    generationType: GenerationType) throws {
        let clientProtocolDelegate = ClientProtocolDelegate(
            baseName: applicationDescription.baseName,
            asyncResultType: SmokeFrameworkCodeGeneration.asyncResultType)
        let mockClientDelegate = MockClientDelegate(
            baseName: applicationDescription.baseName,
            isThrowingMock: false,
            asyncResultType: SmokeFrameworkCodeGeneration.asyncResultType)
        let throwingClientDelegate = MockClientDelegate(
            baseName: applicationDescription.baseName,
            isThrowingMock: true,
            asyncResultType: SmokeFrameworkCodeGeneration.asyncResultType)
        let awsClientDelegate = APIGatewayClientDelegate(
            baseName: applicationDescription.baseName,
            asyncResultType: SmokeFrameworkCodeGeneration.asyncResultType,
            contentType: "application/json", signAllHeaders: false)
        let awsModelErrorsDelegate = SmokeFrameworkModelErrorsDelegate()
        
        generateServerOperationHandlerStubs(generationType: generationType)
        generateServerHanderSelector()
        generateServerApplicationFiles(generationType: generationType)
        generateOperationsContext(generationType: generationType)
        generateOperationTests(generationType: generationType)
        generateTestConfiguration(generationType: generationType)
        generateLinuxMain()
        
        generateClient(delegate: clientProtocolDelegate)
        generateClient(delegate: mockClientDelegate)
        generateClient(delegate: throwingClientDelegate)
        generateClient(delegate: awsClientDelegate)
        generateModelOperationsEnum()
        generateModelOperationClientInput()
        generateModelOperationClientOutput()
        generateModelOperationHTTPInput()
        generateModelOperationHTTPOutput()
        generateModelStructures()
        generateModelTypes()
        generateModelErrors(delegate: awsModelErrorsDelegate)
        generateDefaultInstances(generationType: .internalTypes)
    }
}
