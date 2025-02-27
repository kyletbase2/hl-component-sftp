require 'yaml'

describe 'compiled component sftp' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/dynamic_users.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/dynamic_users/sftp.compiled.yaml") }
  
  context "Resource" do

    
    context "CustomIdentityProviderApi" do
      let(:resource) { template["Resources"]["CustomIdentityProviderApi"] }

      it "is of type AWS::ApiGateway::RestApi" do
          expect(resource["Type"]).to eq("AWS::ApiGateway::RestApi")
      end
      
      it "to have property Name" do
          expect(resource["Properties"]["Name"]).to eq({"Fn::Sub"=>"${EnvironmentName}-sftp-custom-identity-provider"})
      end
      
      it "to have property FailOnWarnings" do
          expect(resource["Properties"]["FailOnWarnings"]).to eq(true)
      end
      
      it "to have property EndpointConfiguration" do
          expect(resource["Properties"]["EndpointConfiguration"]).to eq({"Types"=>["REGIONAL"]})
      end
      
    end
    
    context "TransferIdentityProviderRole" do
      let(:resource) { template["Resources"]["TransferIdentityProviderRole"] }

      it "is of type AWS::IAM::Role" do
          expect(resource["Type"]).to eq("AWS::IAM::Role")
      end
      
      it "to have property AssumeRolePolicyDocument" do
          expect(resource["Properties"]["AssumeRolePolicyDocument"]).to eq({"Version"=>"2012-10-17", "Statement"=>[{"Effect"=>"Allow", "Principal"=>{"Service"=>"transfer.amazonaws.com"}, "Action"=>"sts:AssumeRole"}]})
      end
      
      it "to have property Path" do
          expect(resource["Properties"]["Path"]).to eq("/")
      end
      
      it "to have property Policies" do
          expect(resource["Properties"]["Policies"]).to eq([{"PolicyName"=>"transfer-identity", "PolicyDocument"=>{"Statement"=>[{"Effect"=>"Allow", "Action"=>["apigateway:GET"], "Resource"=>"*"}, {"Effect"=>"Allow", "Action"=>["execute-api:Invoke"], "Resource"=>{"Fn::Sub"=>"arn:aws:execute-api:${AWS::Region}:${AWS::AccountId}:${CustomIdentityProviderApi}/${EnvironmentName}/GET/*"}}]}}])
      end
      
    end
    
    context "ApiGatewayLoggingRole" do
      let(:resource) { template["Resources"]["ApiGatewayLoggingRole"] }

      it "is of type AWS::IAM::Role" do
          expect(resource["Type"]).to eq("AWS::IAM::Role")
      end
      
      it "to have property AssumeRolePolicyDocument" do
          expect(resource["Properties"]["AssumeRolePolicyDocument"]).to eq({"Version"=>"2012-10-17", "Statement"=>[{"Effect"=>"Allow", "Principal"=>{"Service"=>"apigateway.amazonaws.com"}, "Action"=>"sts:AssumeRole"}]})
      end
      
      it "to have property Path" do
          expect(resource["Properties"]["Path"]).to eq("/")
      end
      
      it "to have property Policies" do
          expect(resource["Properties"]["Policies"]).to eq([{"PolicyName"=>"logging", "PolicyDocument"=>{"Statement"=>[{"Effect"=>"Allow", "Action"=>["logs:CreateLogGroup", "logs:CreateLogStream", "logs:DescribeLogGroups", "logs:DescribeLogStreams", "logs:PutLogEvents", "logs:GetLogEvents", "logs:FilterLogEvents"], "Resource"=>"*"}]}}])
      end
      
    end
    
    context "ApiLoggingAccount" do
      let(:resource) { template["Resources"]["ApiLoggingAccount"] }

      it "is of type AWS::ApiGateway::Account" do
          expect(resource["Type"]).to eq("AWS::ApiGateway::Account")
      end
      
      it "to have property CloudWatchRoleArn" do
          expect(resource["Properties"]["CloudWatchRoleArn"]).to eq({"Fn::GetAtt"=>["ApiGatewayLoggingRole", "Arn"]})
      end
      
    end
    
    context "ApiAccessLogGroup" do
      let(:resource) { template["Resources"]["ApiAccessLogGroup"] }

      it "is of type AWS::Logs::LogGroup" do
          expect(resource["Type"]).to eq("AWS::Logs::LogGroup")
      end
      
      it "to have property LogGroupName" do
          expect(resource["Properties"]["LogGroupName"]).to eq({"Fn::Sub"=>"/sftp/${EnvironmentName}/ApiAccess"})
      end
      
      it "to have property RetentionInDays" do
          expect(resource["Properties"]["RetentionInDays"]).to eq(14)
      end
      
    end
    
    context "ApiStage" do
      let(:resource) { template["Resources"]["ApiStage"] }

      it "is of type AWS::ApiGateway::Stage" do
          expect(resource["Type"]).to eq("AWS::ApiGateway::Stage")
      end
      
      it "to have property StageName" do
          expect(resource["Properties"]["StageName"]).to eq({"Ref"=>"EnvironmentName"})
      end
      
      it "to have property DeploymentId" do
          expect(resource["Properties"]["DeploymentId"]).to eq({"Ref"=>"ApiDeployment"})
      end
      
      it "to have property MethodSettings" do
          expect(resource["Properties"]["MethodSettings"]).to eq([{"DataTraceEnabled"=>true, "HttpMethod"=>"*", "LoggingLevel"=>"INFO", "ResourcePath"=>"/*"}])
      end
      
      it "to have property RestApiId" do
          expect(resource["Properties"]["RestApiId"]).to eq({"Ref"=>"CustomIdentityProviderApi"})
      end
      
      it "to have property AccessLogSetting" do
          expect(resource["Properties"]["AccessLogSetting"]).to eq({"DestinationArn"=>{"Fn::GetAtt"=>["ApiAccessLogGroup", "Arn"]}, "Format"=>"{\"requestId\":\"$context.requestId\",\"ip\":\"$context.identity.sourceIp\",\"caller\":\"$context.identity.caller\",\"user\":\"$context.identity.user\",\"requestTime\":\"$context.requestTime\",\"httpMethod\":\"$context.httpMethod\",\"resourcePath\":\"$context.resourcePath\",\"status\":\"$context.status\",\"protocol\":\"$context.protocol\",\"responseLength\":\"$context.responseLength\"}"})
      end
      
    end
    
    context "ApiDeployment" do
      let(:resource) { template["Resources"]["ApiDeployment"] }

      it "is of type AWS::ApiGateway::Deployment" do
          expect(resource["Type"]).to eq("AWS::ApiGateway::Deployment")
      end
      
      it "to have property RestApiId" do
          expect(resource["Properties"]["RestApiId"]).to eq({"Ref"=>"CustomIdentityProviderApi"})
      end
      
      it "to have property StageName" do
          expect(resource["Properties"]["StageName"]).to eq({"Fn::Sub"=>"${EnvironmentName}-deployment"})
      end
      
    end
    
    context "SftpIdentityProviderLambdaPermission" do
      let(:resource) { template["Resources"]["SftpIdentityProviderLambdaPermission"] }

      it "is of type AWS::Lambda::Permission" do
          expect(resource["Type"]).to eq("AWS::Lambda::Permission")
      end
      
      it "to have property Action" do
          expect(resource["Properties"]["Action"]).to eq("lambda:invokeFunction")
      end
      
      it "to have property FunctionName" do
          expect(resource["Properties"]["FunctionName"]).to eq({"Ref"=>"SftpIdentityProvider"})
      end
      
      it "to have property Principal" do
          expect(resource["Properties"]["Principal"]).to eq("apigateway.amazonaws.com")
      end
      
      it "to have property SourceArn" do
          expect(resource["Properties"]["SourceArn"]).to eq({"Fn::Sub"=>"arn:aws:execute-api:${AWS::Region}:${AWS::AccountId}:${CustomIdentityProviderApi}/*"})
      end
      
    end
    
    context "ServersResource" do
      let(:resource) { template["Resources"]["ServersResource"] }

      it "is of type AWS::ApiGateway::Resource" do
          expect(resource["Type"]).to eq("AWS::ApiGateway::Resource")
      end
      
      it "to have property RestApiId" do
          expect(resource["Properties"]["RestApiId"]).to eq({"Ref"=>"CustomIdentityProviderApi"})
      end
      
      it "to have property ParentId" do
          expect(resource["Properties"]["ParentId"]).to eq({"Fn::GetAtt"=>["CustomIdentityProviderApi", "RootResourceId"]})
      end
      
      it "to have property PathPart" do
          expect(resource["Properties"]["PathPart"]).to eq("servers")
      end
      
    end
    
    context "ServerIdResource" do
      let(:resource) { template["Resources"]["ServerIdResource"] }

      it "is of type AWS::ApiGateway::Resource" do
          expect(resource["Type"]).to eq("AWS::ApiGateway::Resource")
      end
      
      it "to have property RestApiId" do
          expect(resource["Properties"]["RestApiId"]).to eq({"Ref"=>"CustomIdentityProviderApi"})
      end
      
      it "to have property ParentId" do
          expect(resource["Properties"]["ParentId"]).to eq({"Ref"=>"ServersResource"})
      end
      
      it "to have property PathPart" do
          expect(resource["Properties"]["PathPart"]).to eq("{serverId}")
      end
      
    end
    
    context "UsersResource" do
      let(:resource) { template["Resources"]["UsersResource"] }

      it "is of type AWS::ApiGateway::Resource" do
          expect(resource["Type"]).to eq("AWS::ApiGateway::Resource")
      end
      
      it "to have property RestApiId" do
          expect(resource["Properties"]["RestApiId"]).to eq({"Ref"=>"CustomIdentityProviderApi"})
      end
      
      it "to have property ParentId" do
          expect(resource["Properties"]["ParentId"]).to eq({"Ref"=>"ServerIdResource"})
      end
      
      it "to have property PathPart" do
          expect(resource["Properties"]["PathPart"]).to eq("users")
      end
      
    end
    
    context "UserNameResource" do
      let(:resource) { template["Resources"]["UserNameResource"] }

      it "is of type AWS::ApiGateway::Resource" do
          expect(resource["Type"]).to eq("AWS::ApiGateway::Resource")
      end
      
      it "to have property RestApiId" do
          expect(resource["Properties"]["RestApiId"]).to eq({"Ref"=>"CustomIdentityProviderApi"})
      end
      
      it "to have property ParentId" do
          expect(resource["Properties"]["ParentId"]).to eq({"Ref"=>"UsersResource"})
      end
      
      it "to have property PathPart" do
          expect(resource["Properties"]["PathPart"]).to eq("{username}")
      end
      
    end
    
    context "GetUserConfigResource" do
      let(:resource) { template["Resources"]["GetUserConfigResource"] }

      it "is of type AWS::ApiGateway::Resource" do
          expect(resource["Type"]).to eq("AWS::ApiGateway::Resource")
      end
      
      it "to have property RestApiId" do
          expect(resource["Properties"]["RestApiId"]).to eq({"Ref"=>"CustomIdentityProviderApi"})
      end
      
      it "to have property ParentId" do
          expect(resource["Properties"]["ParentId"]).to eq({"Ref"=>"UserNameResource"})
      end
      
      it "to have property PathPart" do
          expect(resource["Properties"]["PathPart"]).to eq("config")
      end
      
    end
    
    context "GetUserConfigRequest" do
      let(:resource) { template["Resources"]["GetUserConfigRequest"] }

      it "is of type AWS::ApiGateway::Method" do
          expect(resource["Type"]).to eq("AWS::ApiGateway::Method")
      end
      
      it "to have property AuthorizationType" do
          expect(resource["Properties"]["AuthorizationType"]).to eq("AWS_IAM")
      end
      
      it "to have property HttpMethod" do
          expect(resource["Properties"]["HttpMethod"]).to eq("GET")
      end
      
      it "to have property Integration" do
          expect(resource["Properties"]["Integration"]).to eq({"Type"=>"AWS", "IntegrationHttpMethod"=>"POST", "Uri"=>{"Fn::Join"=>["", ["arn:aws:apigateway:", {"Ref"=>"AWS::Region"}, ":lambda:path/2015-03-31/functions/", {"Fn::GetAtt"=>["SftpIdentityProvider", "Arn"]}, "/invocations"]]}, "IntegrationResponses"=>[{"StatusCode"=>200}], "RequestTemplates"=>{"application/json"=>"{\"username\":\"$input.params('username')\",\"password\":\"$input.params('Password')\",\"serverId\":\"$input.params('serverId')\"}"}})
      end
      
      it "to have property RequestParameters" do
          expect(resource["Properties"]["RequestParameters"]).to eq({"method.request.header.Password"=>false})
      end
      
      it "to have property ResourceId" do
          expect(resource["Properties"]["ResourceId"]).to eq({"Ref"=>"GetUserConfigResource"})
      end
      
      it "to have property RestApiId" do
          expect(resource["Properties"]["RestApiId"]).to eq({"Ref"=>"CustomIdentityProviderApi"})
      end
      
      it "to have property MethodResponses" do
          expect(resource["Properties"]["MethodResponses"]).to eq([{"StatusCode"=>200, "ResponseModels"=>{"application/json"=>{"Ref"=>"GetUserConfigResponseModel"}}}])
      end
      
    end
    
    context "GetUserConfigResponseModel" do
      let(:resource) { template["Resources"]["GetUserConfigResponseModel"] }

      it "is of type AWS::ApiGateway::Model" do
          expect(resource["Type"]).to eq("AWS::ApiGateway::Model")
      end
      
      it "to have property Description" do
          expect(resource["Properties"]["Description"]).to eq("API response for GetUserConfig")
      end
      
      it "to have property RestApiId" do
          expect(resource["Properties"]["RestApiId"]).to eq({"Ref"=>"CustomIdentityProviderApi"})
      end
      
      it "to have property ContentType" do
          expect(resource["Properties"]["ContentType"]).to eq("application/json")
      end
      
      it "to have property Schema" do
          expect(resource["Properties"]["Schema"]).to eq({"$schema"=>"http://json-schema.org/draft-04/schema#", "title"=>"UserUserConfig", "type"=>"object", "properties"=>{"HomeDirectory"=>{"type"=>"string"}, "Role"=>{"type"=>"string"}, "Policy"=>{"type"=>"string"}, "PublicKeys"=>{"type"=>"array", "items"=>{"type"=>"string"}}}})
      end
      
    end
    
    context "CreateDynamicSftpUserTopic" do
      let(:resource) { template["Resources"]["CreateDynamicSftpUserTopic"] }

      it "is of type AWS::SNS::Topic" do
          expect(resource["Type"]).to eq("AWS::SNS::Topic")
      end
      
      it "to have property Subscription" do
          expect(resource["Properties"]["Subscription"]).to eq([{"Protocol"=>"lambda", "Endpoint"=>{"Fn::GetAtt"=>["CreateDynamicSftpUser", "Arn"]}}])
      end
      
    end
    
    context "DynamicSftpUserCreatedTopic" do
      let(:resource) { template["Resources"]["DynamicSftpUserCreatedTopic"] }

      it "is of type AWS::SNS::Topic" do
          expect(resource["Type"]).to eq("AWS::SNS::Topic")
      end
      
    end
    
    context "CreateDynamicSftpUserLambdaPermission" do
      let(:resource) { template["Resources"]["CreateDynamicSftpUserLambdaPermission"] }

      it "is of type AWS::Lambda::Permission" do
          expect(resource["Type"]).to eq("AWS::Lambda::Permission")
      end
      
      it "to have property FunctionName" do
          expect(resource["Properties"]["FunctionName"]).to eq({"Fn::GetAtt"=>["CreateDynamicSftpUser", "Arn"]})
      end
      
      it "to have property Action" do
          expect(resource["Properties"]["Action"]).to eq("lambda:InvokeFunction")
      end
      
      it "to have property Principal" do
          expect(resource["Properties"]["Principal"]).to eq("sns.amazonaws.com")
      end
      
      it "to have property SourceArn" do
          expect(resource["Properties"]["SourceArn"]).to eq({"Ref"=>"CreateDynamicSftpUserTopic"})
      end
      
    end
    
    context "CleanupUsersDailySchedule" do
      let(:resource) { template["Resources"]["CleanupUsersDailySchedule"] }

      it "is of type AWS::Events::Rule" do
          expect(resource["Type"]).to eq("AWS::Events::Rule")
      end
      
      it "to have property ScheduleExpression" do
          expect(resource["Properties"]["ScheduleExpression"]).to eq("rate(1 day)")
      end
      
      it "to have property Targets" do
          expect(resource["Properties"]["Targets"]).to eq([{"Arn"=>{"Fn::GetAtt"=>["CleanupDynamicSftpUsers", "Arn"]}, "Id"=>"cleanup-dyanmic-sftp-users-lambda"}])
      end
      
    end
    
    context "CleanupDynamicSftpUsersLambdaPermission" do
      let(:resource) { template["Resources"]["CleanupDynamicSftpUsersLambdaPermission"] }

      it "is of type AWS::Lambda::Permission" do
          expect(resource["Type"]).to eq("AWS::Lambda::Permission")
      end
      
      it "to have property FunctionName" do
          expect(resource["Properties"]["FunctionName"]).to eq({"Fn::GetAtt"=>["CleanupDynamicSftpUsers", "Arn"]})
      end
      
      it "to have property Action" do
          expect(resource["Properties"]["Action"]).to eq("lambda:InvokeFunction")
      end
      
      it "to have property Principal" do
          expect(resource["Properties"]["Principal"]).to eq("events.amazonaws.com")
      end
      
      it "to have property SourceArn" do
          expect(resource["Properties"]["SourceArn"]).to eq({"Fn::GetAtt"=>["CleanupUsersDailySchedule", "Arn"]})
      end
      
    end
    
    context "SftpServerLoggingRole" do
      let(:resource) { template["Resources"]["SftpServerLoggingRole"] }

      it "is of type AWS::IAM::Role" do
          expect(resource["Type"]).to eq("AWS::IAM::Role")
      end
      
      it "to have property AssumeRolePolicyDocument" do
          expect(resource["Properties"]["AssumeRolePolicyDocument"]).to eq({"Version"=>"2012-10-17", "Statement"=>[{"Effect"=>"Allow", "Principal"=>{"Service"=>"transfer.amazonaws.com"}, "Action"=>"sts:AssumeRole"}]})
      end
      
      it "to have property Path" do
          expect(resource["Properties"]["Path"]).to eq("/")
      end
      
      it "to have property Policies" do
          expect(resource["Properties"]["Policies"]).to eq([{"PolicyName"=>"logging", "PolicyDocument"=>{"Statement"=>[{"Effect"=>"Allow", "Action"=>["logs:CreateLogStream", "logs:DescribeLogStreams", "logs:CreateLogGroup", "logs:PutLogEvents"], "Resource"=>"*"}]}}])
      end
      
    end
    
    context "SftpServer" do
      let(:resource) { template["Resources"]["SftpServer"] }

      it "is of type AWS::Transfer::Server" do
          expect(resource["Type"]).to eq("AWS::Transfer::Server")
      end
      
      it "to have property EndpointType" do
          expect(resource["Properties"]["EndpointType"]).to eq("PUBLIC")
      end
      
      it "to have property IdentityProviderType" do
          expect(resource["Properties"]["IdentityProviderType"]).to eq("API_GATEWAY")
      end
      
      it "to have property IdentityProviderDetails" do
          expect(resource["Properties"]["IdentityProviderDetails"]).to eq({"InvocationRole"=>{"Fn::GetAtt"=>["TransferIdentityProviderRole", "Arn"]}, "Url"=>{"Fn::Sub"=>"https://${CustomIdentityProviderApi}.execute-api.${AWS::Region}.amazonaws.com/${ApiStage}"}})
      end
      
      it "to have property LoggingRole" do
          expect(resource["Properties"]["LoggingRole"]).to eq({"Fn::GetAtt"=>["SftpServerLoggingRole", "Arn"]})
      end
      
      it "to have property Tags" do
          expect(resource["Properties"]["Tags"]).to eq([{"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}, {"Key"=>"Name", "Value"=>{"Fn::Sub"=>"sftp-${EnvironmentName}"}}, {"Key"=>"IdentityProviderUrl", "Value"=>{"Fn::Sub"=>"https://${CustomIdentityProviderApi}.execute-api.${AWS::Region}.amazonaws.com/${ApiStage}"}}])
      end
      
    end
    
    context "SftpServerRecord" do
      let(:resource) { template["Resources"]["SftpServerRecord"] }

      it "is of type AWS::Route53::RecordSet" do
          expect(resource["Type"]).to eq("AWS::Route53::RecordSet")
      end
      
      it "to have property HostedZoneName" do
          expect(resource["Properties"]["HostedZoneName"]).to eq({"Fn::Sub"=>"${EnvironmentName}.${DnsDomain}."})
      end
      
      it "to have property Name" do
          expect(resource["Properties"]["Name"]).to eq({"Fn::Sub"=>"sftp.${EnvironmentName}.${DnsDomain}."})
      end
      
      it "to have property Type" do
          expect(resource["Properties"]["Type"]).to eq("CNAME")
      end
      
      it "to have property TTL" do
          expect(resource["Properties"]["TTL"]).to eq("60")
      end
      
      it "to have property Comment" do
          expect(resource["Properties"]["Comment"]).to eq({"Fn::Join"=>["", [{"Ref"=>"EnvironmentName"}, " sftp server ", {"Fn::GetAtt"=>["SftpServer", "ServerId"]}]]})
      end
      
      it "to have property ResourceRecords" do
          expect(resource["Properties"]["ResourceRecords"]).to eq([{"Fn::Join"=>[".", [{"Fn::GetAtt"=>["SftpServer", "ServerId"]}, "server.transfer", {"Ref"=>"AWS::Region"}, "amazonaws.com"]]}])
      end
      
    end
    
    context "LambdaRoleSftpIdentityProvider" do
      let(:resource) { template["Resources"]["LambdaRoleSftpIdentityProvider"] }

      it "is of type AWS::IAM::Role" do
          expect(resource["Type"]).to eq("AWS::IAM::Role")
      end
      
      it "to have property AssumeRolePolicyDocument" do
          expect(resource["Properties"]["AssumeRolePolicyDocument"]).to eq({"Version"=>"2012-10-17", "Statement"=>[{"Effect"=>"Allow", "Principal"=>{"Service"=>"lambda.amazonaws.com"}, "Action"=>"sts:AssumeRole"}]})
      end
      
      it "to have property Path" do
          expect(resource["Properties"]["Path"]).to eq("/")
      end
      
      it "to have property Policies" do
          expect(resource["Properties"]["Policies"]).to eq([{"PolicyName"=>"cloudwatch-logs", "PolicyDocument"=>{"Statement"=>[{"Effect"=>"Allow", "Action"=>["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams", "logs:DescribeLogGroups"], "Resource"=>["arn:aws:logs:*:*:*"]}]}}, {"PolicyName"=>"get-secrets", "PolicyDocument"=>{"Statement"=>[{"Effect"=>"Allow", "Action"=>["secretsmanager:GetSecretValue"], "Resource"=>{"Fn::Sub"=>"arn:aws:secretsmanager:${AWS::Region}:${AWS::AccountId}:secret:sftp/${EnvironmentName}/*"}}]}}])
      end
      
    end
    
    context "SftpIdentityProvider" do
      let(:resource) { template["Resources"]["SftpIdentityProvider"] }

      it "is of type AWS::Lambda::Function" do
          expect(resource["Type"]).to eq("AWS::Lambda::Function")
      end
      
      it "to have property Environment" do
          expect(resource["Properties"]["Environment"]).to eq({"Variables"=>{"ENVIRONMENT_NAME"=>{"Ref"=>"EnvironmentName"}}})
      end
      
      it "to have property Handler" do
          expect(resource["Properties"]["Handler"]).to eq("index.handler")
      end
      
      it "to have property MemorySize" do
          expect(resource["Properties"]["MemorySize"]).to eq(128)
      end
      
      it "to have property Role" do
          expect(resource["Properties"]["Role"]).to eq({"Fn::GetAtt"=>["LambdaRoleSftpIdentityProvider", "Arn"]})
      end
      
      it "to have property Runtime" do
          expect(resource["Properties"]["Runtime"]).to eq("python3.7")
      end
      
      it "to have property Timeout" do
          expect(resource["Properties"]["Timeout"]).to eq(30)
      end
      
      it "to have property FunctionName" do
          expect(resource["Properties"]["FunctionName"]).to eq("SftpIdentityProvider")
      end
      
    end
    
    context "SftpIdentityProviderLogGroup" do
      let(:resource) { template["Resources"]["SftpIdentityProviderLogGroup"] }

      it "is of type AWS::Logs::LogGroup" do
          expect(resource["Type"]).to eq("AWS::Logs::LogGroup")
      end
      
      it "to have property LogGroupName" do
          expect(resource["Properties"]["LogGroupName"]).to eq("/aws/lambda/SftpIdentityProvider")
      end
      
      it "to have property RetentionInDays" do
          expect(resource["Properties"]["RetentionInDays"]).to eq(90)
      end
      
    end
    
    context "LambdaRoleCreateDynamicSftpUser" do
      let(:resource) { template["Resources"]["LambdaRoleCreateDynamicSftpUser"] }

      it "is of type AWS::IAM::Role" do
          expect(resource["Type"]).to eq("AWS::IAM::Role")
      end
      
      it "to have property AssumeRolePolicyDocument" do
          expect(resource["Properties"]["AssumeRolePolicyDocument"]).to eq({"Version"=>"2012-10-17", "Statement"=>[{"Effect"=>"Allow", "Principal"=>{"Service"=>"lambda.amazonaws.com"}, "Action"=>"sts:AssumeRole"}]})
      end
      
      it "to have property Path" do
          expect(resource["Properties"]["Path"]).to eq("/")
      end
      
      it "to have property Policies" do
          expect(resource["Properties"]["Policies"]).to eq([{"PolicyName"=>"cloudwatch-logs", "PolicyDocument"=>{"Statement"=>[{"Effect"=>"Allow", "Action"=>["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams", "logs:DescribeLogGroups"], "Resource"=>["arn:aws:logs:*:*:*"]}]}}, {"PolicyName"=>"createuser-iam", "PolicyDocument"=>{"Statement"=>[{"Effect"=>"Allow", "Action"=>["iam:GetRole", "iam:CreateRole", "iam:AttachRolePolicy", "iam:PutRolePolicy", "iam:CreatePolicy*"], "Resource"=>[{"Fn::Sub"=>"arn:aws:iam::${AWS::AccountId}:role/*"}, {"Fn::Sub"=>"arn:aws:iam::${AWS::AccountId}:policy/*"}]}]}}, {"PolicyName"=>"createuser-secretsmanager", "PolicyDocument"=>{"Statement"=>[{"Effect"=>"Allow", "Action"=>["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret", "secretsmanager:RestoreSecret", "secretsmanager:PutSecretValue", "secretsmanager:CreateSecret"], "Resource"=>{"Fn::Sub"=>"arn:aws:secretsmanager:${AWS::Region}:${AWS::AccountId}:secret:*"}}]}}, {"PolicyName"=>"createuser-getrandompassword", "PolicyDocument"=>{"Statement"=>[{"Effect"=>"Allow", "Action"=>"secretsmanager:GetRandomPassword", "Resource"=>["*"]}]}}, {"PolicyName"=>"createuser-snspublish", "PolicyDocument"=>{"Statement"=>[{"Effect"=>"Allow", "Action"=>"sns:Publish", "Resource"=>{"Ref"=>"DynamicSftpUserCreatedTopic"}}]}}])
      end
      
    end
    
    context "LambdaRoleCleanupDynamicSftpUsers" do
      let(:resource) { template["Resources"]["LambdaRoleCleanupDynamicSftpUsers"] }

      it "is of type AWS::IAM::Role" do
          expect(resource["Type"]).to eq("AWS::IAM::Role")
      end
      
      it "to have property AssumeRolePolicyDocument" do
          expect(resource["Properties"]["AssumeRolePolicyDocument"]).to eq({"Version"=>"2012-10-17", "Statement"=>[{"Effect"=>"Allow", "Principal"=>{"Service"=>"lambda.amazonaws.com"}, "Action"=>"sts:AssumeRole"}]})
      end
      
      it "to have property Path" do
          expect(resource["Properties"]["Path"]).to eq("/")
      end
      
      it "to have property Policies" do
          expect(resource["Properties"]["Policies"]).to eq([{"PolicyName"=>"cloudwatch-logs", "PolicyDocument"=>{"Statement"=>[{"Effect"=>"Allow", "Action"=>["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams", "logs:DescribeLogGroups"], "Resource"=>["arn:aws:logs:*:*:*"]}]}}, {"PolicyName"=>"cleanupusers-iam", "PolicyDocument"=>{"Statement"=>[{"Effect"=>"Allow", "Action"=>["iam:DeleteRolePolicy", "iam:DeleteRole", "iam:ListRolePolicies"], "Resource"=>{"Fn::Sub"=>"arn:aws:iam::${AWS::AccountId}:role/*SftpAccessRole"}}]}}, {"PolicyName"=>"cleanupusers-secretsmanager", "PolicyDocument"=>{"Statement"=>[{"Effect"=>"Allow", "Action"=>["secretsmanager:GetSecretValue", "secretsmanager:DeleteSecret"], "Resource"=>{"Fn::Sub"=>"arn:aws:secretsmanager:${AWS::Region}:${AWS::AccountId}:secret:sftp/${EnvironmentName}/*"}}]}}, {"PolicyName"=>"cleanupusers-listsecrets", "PolicyDocument"=>{"Statement"=>[{"Effect"=>"Allow", "Action"=>"secretsmanager:ListSecrets", "Resource"=>["*"]}]}}])
      end
      
    end
    
    context "CreateDynamicSftpUser" do
      let(:resource) { template["Resources"]["CreateDynamicSftpUser"] }

      it "is of type AWS::Lambda::Function" do
          expect(resource["Type"]).to eq("AWS::Lambda::Function")
      end
      
      it "to have property Environment" do
          expect(resource["Properties"]["Environment"]).to eq({"Variables"=>{"ENVIRONMENT_NAME"=>{"Ref"=>"EnvironmentName"}, "MESSAGE_S3_PATH"=>{"Ref"=>"S3Message"}, "USER_CREATED_SNS_TOPIC"=>{"Ref"=>"DynamicSftpUserCreatedTopic"}}})
      end
      
      it "to have property Handler" do
          expect(resource["Properties"]["Handler"]).to eq("index.handler")
      end
      
      it "to have property MemorySize" do
          expect(resource["Properties"]["MemorySize"]).to eq(128)
      end
      
      it "to have property Role" do
          expect(resource["Properties"]["Role"]).to eq({"Fn::GetAtt"=>["LambdaRoleCreateDynamicSftpUser", "Arn"]})
      end
      
      it "to have property Runtime" do
          expect(resource["Properties"]["Runtime"]).to eq("python3.8")
      end
      
      it "to have property Timeout" do
          expect(resource["Properties"]["Timeout"]).to eq(60)
      end
      
    end
    
    context "CreateDynamicSftpUserLogGroup" do
      let(:resource) { template["Resources"]["CreateDynamicSftpUserLogGroup"] }

      it "is of type AWS::Logs::LogGroup" do
          expect(resource["Type"]).to eq("AWS::Logs::LogGroup")
      end
      
      it "to have property LogGroupName" do
          expect(resource["Properties"]["LogGroupName"]).to eq("/aws/lambda/CreateDynamicSftpUser")
      end
      
      it "to have property RetentionInDays" do
          expect(resource["Properties"]["RetentionInDays"]).to eq(90)
      end
      
    end
    
    context "CleanupDynamicSftpUsers" do
      let(:resource) { template["Resources"]["CleanupDynamicSftpUsers"] }

      it "is of type AWS::Lambda::Function" do
          expect(resource["Type"]).to eq("AWS::Lambda::Function")
      end
      
      it "to have property Environment" do
          expect(resource["Properties"]["Environment"]).to eq({"Variables"=>{"ENVIRONMENT_NAME"=>{"Ref"=>"EnvironmentName"}}})
      end
      
      it "to have property Handler" do
          expect(resource["Properties"]["Handler"]).to eq("index.handler")
      end
      
      it "to have property MemorySize" do
          expect(resource["Properties"]["MemorySize"]).to eq(128)
      end
      
      it "to have property Role" do
          expect(resource["Properties"]["Role"]).to eq({"Fn::GetAtt"=>["LambdaRoleCleanupDynamicSftpUsers", "Arn"]})
      end
      
      it "to have property Runtime" do
          expect(resource["Properties"]["Runtime"]).to eq("python3.8")
      end
      
      it "to have property Timeout" do
          expect(resource["Properties"]["Timeout"]).to eq(60)
      end
      
    end
    
    context "CleanupDynamicSftpUsersLogGroup" do
      let(:resource) { template["Resources"]["CleanupDynamicSftpUsersLogGroup"] }

      it "is of type AWS::Logs::LogGroup" do
          expect(resource["Type"]).to eq("AWS::Logs::LogGroup")
      end
      
      it "to have property LogGroupName" do
          expect(resource["Properties"]["LogGroupName"]).to eq("/aws/lambda/CleanupDynamicSftpUsers")
      end
      
      it "to have property RetentionInDays" do
          expect(resource["Properties"]["RetentionInDays"]).to eq(90)
      end
      
    end
    
  end

end