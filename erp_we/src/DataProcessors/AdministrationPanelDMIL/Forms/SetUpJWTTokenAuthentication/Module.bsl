#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	KeyToMapUsers1CDocumentManagement =
		Constants.KeyToMapUsers1CDocumentManagement.Get();
	AccessTokenSignatureKey1CDocumentManagement =
		Constants.AccessTokenSignatureKey1CDocumentManagement.Get();
	
	If Not ValueIsFilled(KeyToMapUsers1CDocumentManagement) Then
		KeyToMapUsers1CDocumentManagement =
			Enums.KeysToMapUsers1CDocumentManagement.OSUser;
	EndIf;
	
	If Not ValueIsFilled(AccessTokenSignatureKey1CDocumentManagement) Then
		GenerateNewKeyAutomatically = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetAvailability();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GenerateNewKeyAutomaticallyOnChange(Item)
	
	SetAvailability();
	
EndProcedure

&AtClient
Procedure KeyToMapUsers1CDocumentManagementOnChange(Item)
	
	If ValueIsFilled(AccessTokenSignatureKey1CDocumentManagement)
			Or GenerateNewKeyAutomatically Then
		GenerateDescriptionOnServer();
	Else
		DescriptionOfPublication = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure AccessTokenSignatureKey1CDocumentManagementOnChange(Item)
	
	If ValueIsFilled(AccessTokenSignatureKey1CDocumentManagement)
			Or GenerateNewKeyAutomatically Then
		GenerateDescriptionOnServer();
	Else
		DescriptionOfPublication = "";
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GenerateADescription(Command)
	
	If Not ValueIsFilled(AccessTokenSignatureKey1CDocumentManagement)
			And Not GenerateNewKeyAutomatically Then
		CurrentItem = Items.AccessTokenSignatureKey1CDocumentManagement;
		ShowMessageBox(, NStr("vi = 'Chưa chỉ ra khóa chữ ký token JWT.';
								|ru = 'Не указан ключ подписи JWT-токенов.';
								|en = 'A signature key of JWT tokens is not specified.'; fa = 'A signature key of JWT tokens is not specified.';
								|it = 'Не указан ключ подписи JWT-токенов.';
								|pl = 'A signature key of JWT tokens is not specified.';
								|tr = 'JWT belirteci imzalama anahtarı belirtilmedi.'"));
		Return;
	EndIf;
	
	GenerateDescriptionOnServer();
	
EndProcedure

&AtClient
Procedure ApplyEnteredSettings(Command)
	
	If Not ValueIsFilled(AccessTokenSignatureKey1CDocumentManagement)
			And Not GenerateNewKeyAutomatically Then
		CurrentItem = Items.AccessTokenSignatureKey1CDocumentManagement;
		ShowMessageBox(, NStr("vi = 'Chưa chỉ ra khóa chữ ký token JWT.';
								|ru = 'Не указан ключ подписи JWT-токенов.';
								|en = 'A signature key of JWT tokens is not specified.'; fa = 'A signature key of JWT tokens is not specified.';
								|it = 'Не указан ключ подписи JWT-токенов.';
								|pl = 'A signature key of JWT tokens is not specified.';
								|tr = 'JWT belirteci imzalama anahtarı belirtilmedi.'"));
		Return;
	EndIf;
	
	If Not ValueIsFilled(DescriptionOfPublication) Then
		CurrentItem = Items.GenerateADescription;
		ShowMessageBox(, NStr("vi = 'Chưa tạo mô tả web-serivice 1C:Document management.';
								|ru = 'Не сформировано описание веб-сервиса 1С:Документооборот.';
								|en = 'The details of 1C:Document Management web service are not generated.'; fa = 'The details of 1C:Document Management web service are not generated.';
								|it = 'Не сформировано описание веб-сервиса 1С:Документооборот.';
								|pl = 'The details of 1C:Document Management web service are not generated.';
								|tr = '1C:Document Management web servisinin ayrıntıları oluşturulmadı.'"));
		Return;
	EndIf;
	
	ApplySettingsOnServer();
	
	Close(True);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateDescriptionOnServer()
	
	If GenerateNewKeyAutomatically Then
		Hash = New DataHashing(HashFunction.SHA256);
		Hash.Append(String(New UUID));
		AccessTokenSignatureKey1CDocumentManagement = Base64String(Hash.HashSum);
	EndIf;
	
	RecipientsOfAccessToken = IntegrationWith1CDocumentManagementCore.RecipientsOfAccessToken();
	NameOfDocumentManagementWebService = IntegrationWith1CDocumentManagementCore.NameOfDocumentManagementWebService();
	AliasOfDocumentManagementWebService =
		IntegrationWith1CDocumentManagementCore.AliasOfDocumentManagementWebService();
	IssuerOfAccessToken = IntegrationWith1CDocumentManagementCore.IssuerOfAccessToken();
	
	If KeyToMapUsers1CDocumentManagement =
			Enums.KeysToMapUsers1CDocumentManagement.IBUserName Then
		NameOfUserMappingKey = "name";
	ElsIf KeyToMapUsers1CDocumentManagement =
			Enums.KeysToMapUsers1CDocumentManagement.OSUser Then
		NameOfUserMappingKey = "OSUser";
	ElsIf KeyToMapUsers1CDocumentManagement =
			Enums.KeysToMapUsers1CDocumentManagement.Email Then
		NameOfUserMappingKey = "email";
	EndIf;
	
	PublicationDescriptionTemplate =
		"<point name=""%1""
		|		alias=""%2""
		|		enable=""true""
		|		reuseSessions=""dontuse""
		|		sessionMaxAge=""20""
		|		poolSize=""10""
		|		poolTimeout=""5"">
		|		<accessTokenAuthentication>
		|		<accessTokenRecepientName>%3</accessTokenRecepientName>
		|			<issuers>
		|				<issuer
		|					name=""%4""
		|					authenticationClaimName=""sub""
		|					authenticationUserPropertyName=""%5""
		|					keyInformation=""%6""
		|				/>
		|			</issuers>
		|		</accessTokenAuthentication>
		|</point>";
	
	DescriptionOfPublication = StrTemplate(PublicationDescriptionTemplate,
		NameOfDocumentManagementWebService,
		AliasOfDocumentManagementWebService,
		RecipientsOfAccessToken[0],
		IssuerOfAccessToken,
		NameOfUserMappingKey,
		AccessTokenSignatureKey1CDocumentManagement);
	
EndProcedure

&AtServer
Procedure ApplySettingsOnServer()
	
	Constants.KeyToMapUsers1CDocumentManagement.Set(KeyToMapUsers1CDocumentManagement);
	Constants.AccessTokenSignatureKey1CDocumentManagement.Set(AccessTokenSignatureKey1CDocumentManagement);
	
EndProcedure

&AtClient
Procedure SetAvailability()
	
	Items.AccessTokenSignatureKey1CDocumentManagement.Enabled = Not GenerateNewKeyAutomatically;
	Items.AccessTokenSignatureKey1CDocumentManagement.AutoMarkIncomplete = Not GenerateNewKeyAutomatically;
	
EndProcedure

#EndRegion