#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	WebServiceAddress = Parameters.WebServiceAddress;
	NodeID = Parameters.NodeID;
	NodeName = Parameters.NodeName;
	
	If Not IsBlankString(NodeName) Then
		Title = StrTemplate(NStr("vi = 'Kết nối đến nút %1';
								|ru = 'Подключение к узлу %1';
								|en = 'Connect to the %1 node'; fa = 'Connect to the %1 node';
								|it = 'Подключение к узлу %1';
								|pl = 'Connect to the %1 node';
								|tr = '%1 düğümüne bağlantı'"), NodeName);
		Items.ExplanationWebServiceAddress.Title =
			StrTemplate(NStr("vi = 'Địa chỉ đăng tải web-servce của nút %1.';
							|ru = 'Адрес, по которому опубликован веб-сервис узла %1.';
							|en = 'Address where the web service of the %1 node is published.'; fa = 'Address where the web service of the %1 node is published.';
							|it = 'Адрес, по которому опубликован веб-сервис узла %1.';
							|pl = 'Address where the web service of the %1 node is published.';
							|tr = '%1 düğümünün web servisinin yayınlandığı adres.'"), NodeName);
	EndIf;
	
	IBUserName =
		IntegrationWith1CDocumentManagementCore.IBUserNameForVDOAuthorization(
			Users.CurrentUser());
#If Not WebClient Then
	If Not ValueIsFilled(IBUserName) Then
		// Add the IP user name to the selection list.
		IBUser = InfoBaseUsers.CurrentUser();
		IBUserName = IBUser.Name;
	EndIf;
#EndIf
	
	If ValueIsFilled(IBUserName) Then
		// Add the IP user name to the selection list.
		Items.UserName.ChoiceList.Add(IBUserName);
		Items.UserName.DropListButton = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Logon(Command)
	
	Close(ConnectATServer());
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ConnectATServer()
	
	AuthorizationSettings =
		IntegrationWith1CDocumentManagementCoreClientServer.AuthorizationSettingsIn1CDocumentManagement();
	AuthorizationSettings.UserName = UserName;
	AuthorizationSettings.Password = Password;
	AuthorizationSettings.OSAuthenticationIsUsed = False;
	AuthorizationSettings.JWTAuthenticationIsUsed = False;
	AuthorizationSettings.Use_Cache = False;
	
	RaiseException1 = True;
	Proxy = IntegrationWith1CDocumentManagementCore.GetProxy(
		RaiseException1,
		AuthorizationSettings,
		WebServiceAddress,,
		True);
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetThisNodeRequest");
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	If Response.node.objectID.id <> NodeID Then
		Raise StrTemplate(
			NStr("vi = 'Theo địa chỉ ""%1"" đăng tải nút ""%2"". Cần nhập địa chỉ đăng tải nút ""%3"".';
				|ru = 'По адресу ""%1"" опубликован узел ""%2"". Требуется указать адрес публикации узла ""%3"".';
				|en = 'At ""%1"", the ""%2"" node is published. Specify a publication URL for the ""%3"" node.'; fa = 'At ""%1"", the ""%2"" node is published. Specify a publication URL for the ""%3"" node.';
				|it = 'По адресу ""%1"" опубликован узел ""%2"". Требуется указать адрес публикации узла ""%3"".';
				|pl = 'At ""%1"", the ""%2"" node is published. Specify a publication URL for the ""%3"" node.';
				|tr = '""%2"" düğümü ""%1"" adresine göre yayınlandı. ""%3"" düğümünün yayın adresinin belirtilmesi gerekmektedir.'"),
			WebServiceAddress,
			Response.node.name,
			NodeName);
	EndIf;
	
	DataOfSUBAsset = InformationRegisters.DataOf1CDocumentManagementNodes.NewDataOfSUBAsset();
	DataOfSUBAsset.WebServiceAddress = WebServiceAddress;
	
	InformationRegisters.DataOf1CDocumentManagementNodes.ToSetDataOfSUBAsset(NodeID, DataOfSUBAsset);
	
	Return DataOfSUBAsset;
	
EndFunction

#EndRegion