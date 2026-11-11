#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CorpFunctionalityIsAvailable = IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.0.0.0.CORP");
	
	ID = Parameters.id;
	Type = Parameters.type;
	If Not ValueIsFilled(Type) Then
		Type = "DMInternalDocument";
	EndIf;
	Parameters.Property("ExternalObject", ExternalObject);
	
	AbbreviatedNameOfConfiguration = IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	
	AddressOfObjectSBinaryData =
		IntegrationWith1CDocumentManagementCoreClientServer.AddressOfObjectSBinaryData(
			UUID);
	
	CurCurrentUserAndEmployees =
		IntegrationWith1CDocumentManagementCoreCached.Current1CDocumentManagementUser();
	CurUserXDTO = CurCurrentUserAndEmployees[0];
	CurrentUserBefore = CurUserXDTO.name;
	CurrentUserBeforeID = CurUserXDTO.objectID.ID;
	CurrentUserBeforeType = CurUserXDTO.objectID.type;
	
	// We consider the data of the document.
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	If ValueIsFilled(ID) And ValueIsFilled(Type) Then
		
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRetrieveRequest");
		ListOfObjects = Query.objectIDs; // XDTOList
		ListOfObjects.Add(ThisObjectBefore(Proxy));
		
		Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
		
		XDTODataObject = Result.objects[0];
		If Not ValueIsFilled(ExternalObject) Then
			ExternalObjects = IntegrationWith1CDocumentManagementCore.LinksToExternalObjects(XDTODataObject);
			If ExternalObjects.Count() <> 0 Then
				ExternalObject = ExternalObjects[0];
			EndIf;
		EndIf;
		
	Else // A new document.
		
		Modified = True;
		
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetNewObjectRequest");
		Query.type = Type;
		
		If ValueIsFilled(Parameters.Rule) Then
			
			RuleDetails = Common.ObjectAttributesValues(
				Parameters.Rule,
				"DoNotCreateRelationsByLinks, Template, TemplateID, TemplateType");
			
			// Filling out documents according to templates.
			If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.0.8.1") Then
				
				If ValueIsFilled(RuleDetails.TemplateID) Then
					
					XDTOTemplate = IntegrationWith1CDocumentManagementCore.CreateObject(
						Proxy,
						RuleDetails.TemplateType);
					XDTOTemplate.name = RuleDetails.Template;
					XDTOTemplate.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
						Proxy,
						RuleDetails.TemplateID,
						RuleDetails.TemplateType);
					
					Query.dataSource = XDTOTemplate;
					
				EndIf;
				
			EndIf;
			
		Else // An empty document is created.
			Items.GroupPages.CurrentPage = Items.BankingDetailsPage;
			
		EndIf;
		
		Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
		
		XDTODataObject = Result;
		
	EndIf;
	
	If IntegrationWith1CDocumentManagementCached.UseTermCorrespondents() Then
		Items.CounterpartyGroup.Title = NStr("vi = 'Cơ sở thông tin trao đổi';
											|ru = 'Корреспондент';
											|en = 'Correspondent'; fa = 'Correspondent';
											|it = 'Corrispondente';
											|pl = 'Correspondent';
											|tr = 'Muhabir'");
		Items.Counterparty.Title = NStr("vi = 'Cơ sở thông tin trao đổi';
										|ru = 'Корреспондент';
										|en = 'Correspondent'; fa = 'Correspondent';
										|it = 'Corrispondente';
										|pl = 'Correspondent';
										|tr = 'Muhabir'");
	EndIf;
	
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.28.12") Then
		Items.SignedBy.Visible = False;
		Items.SignedFromCounterparty.Visible = False;
	EndIf;
	
	UseRelatedDocuments1CDocumentManagement =
		Constants.UseRelatedDocuments1CDocumentManagement.Get();
	
	// Fill in the form with the document data.
	ReadObjectIntoForm(XDTODataObject);
	IntegrationWith1CDocumentManagementCoreServerCall.UpdateFileList(
		XDTODataObject.files, Files, Items.FilesDescription);
	
	// We will process the resolutions.
	If XDTODataObject.Properties().Get("resolutions") <> Undefined And XDTODataObject.resolutions.Count() <> 0 Then
		IntegrationWith1CDocumentManagement.UpdateResolutionsPresentation(
			XDTODataObject.resolutions,
			HTMLPresentationResolutions,
			Items.ResolutionPage);
	Else
		Items.ResolutionPage.Visible = False;
	EndIf;
	
	// We will process the visas.
	If XDTODataObject.Properties().Get("visas") <> Undefined And XDTODataObject.visas.Count() <> 0 Then
		IntegrationWith1CDocumentManagement.UpdateVisaApprovals(
			XDTODataObject.visas,
			VisaApprovals,
			Items.VisaPage);
	Else
		Items.VisaPage.Visible = False;
	EndIf;
	
	SettingsBefore = IntegrationWith1CDocumentManagementCoreCached.GetSettings();
	
	Items.FillFileWithDocumentData.Visible = SettingsBefore.UseAutoCompleteFiles;
	
	// Let's apply the settings for using the EP in the DO and in the IC.
	UseElectronicDigitalSignaturesVBSP =
		IntegrationWith1CDocumentManagementCoreServerCall.UseElectronicDigitalSignatures();
	
	If SettingsBefore.UseElectronicDigitalSignatures = False Then
		Items.FilesSignedEncryptedPictureNumber.Visible = False;
		Items.ItemInstancePage.Visible = False;
		Items.EPTeamGroup.Visible = False;
	Else
		FillSignatureList(XDTODataObject.signatures, XDTODataObject.files);
		If XDTODataObject.IsSet("keyPropertiesValue") Then
			AddressOfObjectSBinaryData.AddressOfDocumentImpression = PutToTempStorage(
				XDTODataObject.keyPropertiesValue, UUID);
		EndIf;
	EndIf;
	
	If SettingsBefore.UseElectronicDigitalSignatures = False
			Or UseElectronicDigitalSignaturesVBSP = False Then
		Items.Sign.Visible = False;
		Items.AddDSFromFile.Visible = False;
		Items.FormSignDocument.Visible = False;
	EndIf;
	
	// Fill out the document on the associated IP object.
	If Not ValueIsFilled(ID)
			And ValueIsFilled(ExternalObject)
			And ValueIsFilled(Parameters.Rule) Then
		
		Catalogs.RulesForIntegrationWith1CDocumentManagement.FillInMapItemFormUpToRule(
			ExternalObject, ThisObject, Parameters.Rule);
		IntegrationWith1CDocumentManagementCoreOverridable.FillOutFormFromConsumer(
			ExternalObject, ThisObject);
		
		Objects = New Array;
		Objects.Add(New Structure("ID, Type", DocumentKindID, DocumentKindType));
		If OrganizationID <> "" And OrganizationType = "DMOrganization" Then
			Objects.Add(New Structure("ID, Type", OrganizationID, OrganizationType));
		EndIf;
		For Each String In Parties Do
			If String.PartyType = "DMCorrespondent" Then
				Objects.Add(New Structure("ID, Type", String.PartyID, String.PartyType));
			EndIf;
		EndDo;
		ObjectsDataBefore = IntegrationWith1CDocumentManagementCore.GetObjects(Proxy, Objects);
		
		DataProcessors.IntegrationWith1CDocumentManagementCore.WhenChangingViewOnDocumentForm(
			ThisObject,
			ObjectsDataBefore);
		
		For Each String In Parties Do
			legalPrivatePersonID = "";
			If String.PartyType = "DMCorrespondent" Then
				For Each Item In ObjectsDataBefore Do
					If Item.objectID.ID = String.PartyID And Item.objectID.type = String.PartyType Then
						legalPrivatePersonID = Item.legalPrivatePerson.objectID.ID;
						Break;
					EndIf;
				EndDo;
			EndIf;
			FillInAdditionalData(String, String.PartyType, legalPrivatePersonID);
		EndDo;
		
		ValidityPeriodPresentation =
			IntegrationWith1CDocumentManagementClientServer.PresentationOfValidityPeriodOfDocument(
				ValidityStartDate,
				Permanent,
				ValidityEndDate,
				ExtensionProcedureID,
				ExtensionProcedure);
		
		DataProcessors.IntegrationWith1CDocumentManagement.SetDocumentStates(ThisObject, XDTODataObject);
		
		If UseRelatedDocuments1CDocumentManagement
				And IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("2.1.0.1")
				And Not RuleDetails.DoNotCreateRelationsByLinks Then
			
			DataProcessors.IntegrationWith1CDocumentManagement.FillInLinksOfNewDocument(ThisObject,
				ExternalObject,
				Items.LinkPage);
			
		EndIf;
		
	EndIf;
	
	SynchronizeITCHAttributesCounterparties();
	MultipleCounterparties = (Counterparties.Count() > 1);
	SetCounterpartyVisibility();
	
	GeneratePresentationOfCFItems();
	
	// Let's set the visibility of the file copy command.
	Items.FillFilesByCopying.Visible = False;
	If ValueIsFilled(ExternalObject) Then
		If IntegrationWith1CDocumentManagementCoreServerCall.ThereAreStoredVISFiles(ExternalObject) Then
			Items.FillFilesByCopying.Visible = True;
			Items.FillFilesByCopying.Enabled = (Files.Count() = 0);
		EndIf;
	EndIf;
	
	If Parameters.ReadOnly Then
		ReadOnly = True;
	EndIf;
	
	// Timing.
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP") Then
		Items.FormSpecifyLaborCosts.Visible = False;
		Items.FormSwitchTiming.Visible = False;
	EndIf;
	FileCaptureIsAvailable = IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.4.9.1");
	
	UpdateScenery();
	
	IntegrationWith1CDocumentManagementCoreOverridable.AdditionalProcessingOfDocumentForm(
		ThisObject,
		Cancel,
		StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TransferCounterpartyAndOrganizationFromPartySTsToDetails();
	
	UpdateOverview();
	UpdateAmountDisplay();
	UpdateDisplayOfVATAmount();
	UpdatePageTitleCounterparties();
	UpdatePageTitleProducts();
	
	If ValueIsFilled(AddressForLinkedDocumentFiles) Then
		AttachIdleHandler("UpdatingRelatedDocumentFiles", 1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ClosingWithParameter Then
		Return;
	EndIf;
	
	If Modified Then
		
		Notification = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		WarningText = "";
		CommonClient.ShowFormClosingConfirmation(
			Notification,
			Cancel,
			Exit,,
			WarningText);
		
	Else
		
		Cancel = True;
		AttachIdleHandler("CloseWithParameter", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Recording_1CDocumentManagementFile"
			And ID <> ""
			And TypeOf(Parameter) = Type("Structure")
			And Parameter.Property("FileOperation")
			And Parameter.FileOperation.InformFileListForm
			And Parameter.Property("NotifyDocumentCard")
			And Parameter.NotifyDocumentCard = True
			And Parameter.Property("FileOwner")
			And Parameter.FileOwner = ID Then
		UpdateFileListClient();
		ReadAndUpdateListOfSignatures();
		
	ElsIf EventName = "Recording_1CDocumentManagementTimeSpent" And Source = ID Then
		TimekeepingEnabled = False;
		StartDateOfTimekeeping = '00010101';
		SetPropertiesOfTimekeepingElementsServer();
		
	ElsIf EventName = "DocumentManagement_SelectAValueFromTheListCompletion" And Source = ThisObject Then
		If Parameter = "DocumentKind" Then
			WhenChangingDocumentView();
			
		ElsIf Parameter = "Recipient" Then
			Items.ExpenseReport.Visible = (RecipientType = "DMUser"
				Or IntegrationWith1CDocumentManagementCoreServerCall.TypeNameXDTO(
					RecipientType) = "DMUser");
			
		ElsIf Parameter = "Counterparty" Then
			ClearDocumentContacts();
			
		EndIf;
		
	ElsIf EventName = "DocumentManagement_SelectAValueFromTheDropDownListCompletion"
			And Source = ThisObject And Parameter.Attribute = "VATRate" Then
		WhenChangingGoodsVATRate(Items.Goods.CurrentData);
		
	ElsIf EventName = "DocumentManagement_SelectAValueFromTheDropDownListCompletion"
			And Source = ThisObject And Parameter.Attribute = "Organization" Then
		ThisOrganization = ThisOrganization(OrganizationType, OrganizationID);
		UpdateVATVisibility(ThisOrganization);
		
	ElsIf EventName = "DocumentManagement_AddingALink" And Parameter.ID = ID Then
		ExternalObject = Parameter.Object;
		UpdateScenery();
		
	ElsIf EventName = "DocumentManagement_DeletingALink" And Parameter.ID = ID Then
		ExternalObject = Undefined;
		UpdateScenery();
		
	ElsIf EventName = "Recording_1CDocumentManagementBusinessProcess" Then
		For Each SubjectOf In Parameter.Subjects Do
			If SubjectOf.ID = ID Then
				RefreshStatus();
				Break;
			EndIf;
		EndDo;
		
	ElsIf EventName = "Recording_1CDocumentManagementDocument" Then
		For Each LinkTypeString_ In LinkTree.GetItems() Do
			For Each DocumentLine In LinkTypeString_.GetItems() Do
				If DocumentLine.Ref = Parameter.ExternalObject
						And Not ValueIsFilled(DocumentLine.ID) Then
					DocumentLine.ID = Parameter.ID;
					DocumentLine.Type = Parameter.type;
					DocumentLine.Title = Parameter.name;
				EndIf;
			EndDo;
		EndDo;
		UpdateScenery();
		
	ElsIf EventName = "DocumentManagement_SelectAValueFromTheListInTheTableCompletion" And Source = ThisObject Then
		If Parameter.Attribute = "Party" Then
			CleanTSSideContacts();
			FillInAdditionalData(
				Parameter.Data,
				Parameter.Result.AttributeType,
				?(Parameter.Result.Property("legalPrivatePersonID"),
					Parameter.Result.legalPrivatePersonID,
					""));
			TransferCounterpartyAndOrganizationFromPartySTsToDetails();
			
		ElsIf Parameter.Attribute = "Products" Then
			ProductData_1 = ProductData_1(Parameter.Data.ProductsType, Parameter.Data.ProductsID);
			FillInAdditionalProductData(ProductData_1, Parameter.Data);
			
		ElsIf Parameter.Attribute = "Counterparty" Then
			ClearContactsTSCounterparties();
			
		EndIf;
		
	ElsIf EventName = "UpdateOverview" And Source = ThisObject Then
		UpdateOverview();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

///////////////////////////////////////////////////////////////////////////////////////////////////
// Overall

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	UpdateOverview();
	
EndProcedure

&AtClient
Procedure LinkObjectClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ShowValue(, ExternalObject);
	
EndProcedure

&AtClient
Procedure LinkCreateClick(Item)
	
	If Not ValueIsFilled(ID) Then
		WriteObject();
	EndIf;
	
	CallbackDescription = New CallbackDescription("LinkCreateClickCompletion", ThisObject);
	If FillingRules.Count() = 1 Then
		RunCallback(CallbackDescription, FillingRules[0]);
	Else
		ShowChooseFromMenu(CallbackDescription, FillingRules, Items.LinkCreate);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectLinkClick(Item)
	
	If Not ValueIsFilled(ID) Then
		WriteObject();
	EndIf;
	
	CallbackDescription = New CallbackDescription("SelectLinkClickCompletion", ThisObject);
	If FillingRules.Count() = 1 Then
		RunCallback(CallbackDescription, FillingRules[0]);
	Else
		ShowChooseFromMenu(CallbackDescription, FillingRules, Items.SelectLink);
	EndIf;
	
EndProcedure

&AtClient
Procedure LinkClearClick(Item)
	
	If Not ValueIsFilled(ExternalObject) Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("LinkClearClickCompletion", ThisObject);
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Xóa so sánh đối với
					|%1?';
					|ru = 'Очистить соответствие для
					|%1?';
					|en = 'Clear match for
					|%1?'; fa = 'Clear match for
					|%1?';
					|it = 'Cancellare corrispondenza per
					|%1?';
					|pl = 'Wyczyścić zgodność dla
					|%1?';
					|tr = '
					|%1için uygunluğu temizle?'"), String(ExternalObject));
	
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Xóa';
											|ru = 'Очистить';
											|en = 'Clear'; fa = 'پاک کردن';
											|it = 'Cancellare';
											|pl = 'Clear';
											|tr = 'Temizle'"));
	Buttons.Add(DialogReturnCode.No, NStr("vi = 'Không xóa';
											|ru = 'Не очищать';
											|en = 'Do not clean up'; fa = 'پاک‌سازی نشود';
											|it = 'Non cancellare';
											|pl = 'Nie oczyszczaj';
											|tr = 'Temizlememek'"));
	
	ShowQueryBox(Notification, QueryText, Buttons,, DialogReturnCode.No);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Overview

&AtClient
Procedure PresentationHTMLOnClick(Item, EventData, StandardProcessing)
	
	StandardProcessing = False;
	If Not ValueIsFilled(EventData.Href) Or ID = "" Then
		Return;
	EndIf;
	
	If Left(EventData.Href, 6) = "v8doc:" Then
		
		FieldNavigationLink = Mid(EventData.Href, 7);
		IntegrationWith1CDocumentManagementCoreClient.OpenURL(FieldNavigationLink);
		
	ElsIf Left(EventData.Href, 5) = "dmil:" Then
		
		FieldNavigationLink = Mid(EventData.Href, 6);
		SplitLink = StringFunctionsClientServer.SplitStringIntoSubstringsArray(FieldNavigationLink, ":");
		ObjectType = SplitLink[0];
		ObjectID = SplitLink[1];
		
		If SplitLink.Count() = 2 Then
			IntegrationWith1CDocumentManagementCoreClient.OpenObject(
				ObjectType,
				ObjectID,
				Item);
			
		ElsIf SplitLink.Count() = 3 Then
			AttributeName = SplitLink[2];
			If AttributeName = "status" Then
				IntegrationWith1CDocumentManagementClient.OpenDocumentStates(
					ThisObject,
					Items.State.ReadOnly);
			ElsIf AttributeName = "term" Then
				IntegrationWith1CDocumentManagementClient.OpenDocumentExpiration(
					ThisObject,
					Items.ValidityPeriodPresentation.ReadOnly);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Attributes

///////////////////////////////////////////////////////////////////////////////////////////////////
// DocumentKind

&AtClient
Procedure DocumentKindStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheList(
		"DMInternalDocumentType", "DocumentKind", ThisObject);
	
EndProcedure

&AtClient
Procedure DocumentKindChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"DocumentKind", ValueSelected, StandardProcessing, ThisObject);
	
	WhenChangingDocumentView();
	
EndProcedure

&AtClient
Procedure DocumentKindAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
		StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMInternalDocumentType", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure DocumentKindTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMInternalDocumentType", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"DocumentKind", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
			
			WhenChangingDocumentView();
		EndIf;
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Organization

&AtClient
Procedure OrganizationStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheDropDownList(
		"DMOrganization", "Organization", ThisObject);
	
EndProcedure

&AtClient
Procedure OrganizationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Organization", ValueSelected, StandardProcessing, ThisObject);
	
	UpdateVATVisibility(ValueSelected);
	
EndProcedure

&AtClient
Procedure OrganizationAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMOrganization", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
		StandardProcessing)
	
	OrganizationID = "";
	OrganizationType = "";
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMOrganization", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Organization", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
			
			UpdateVATVisibility(ChoiceData[0].Value);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function ThisOrganization(OrganizationType, OrganizationID)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ThisOrganization = New Structure();
	
	XDTOOrganization = IntegrationWith1CDocumentManagementCore.GetObject(
		Proxy,
		OrganizationType,
		OrganizationID);
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOOrganization, "VATpayer") Then
		ThisOrganization.Insert("VATpayer", XDTOOrganization.VATpayer);
	EndIf;
	
	Return ThisOrganization;
	
EndFunction

&AtClient
Procedure UpdateVATVisibility(OrganizationValue)
	
	If OrganizationValue.Property("VATpayer") Then
		ConsiderVAT = OrganizationValue.VATpayer;
	Else
		ConsiderVAT = True;
	EndIf;
	
	Items.VATAmount.Visible = Items.Sum.Visible And ConsiderVAT;
	Items.GoodsVATRate.Visible = Items.Sum.Visible And ConsiderVAT;
	Items.GoodsVATAmount.Visible = Items.Sum.Visible And ConsiderVAT;
	
EndProcedure

&AtClient
Procedure OrganizationClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	Organization = "";
	OrganizationID = "";
	OrganizationType = "";
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// SignedBy

&AtClient
Procedure SignedByStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectUserFromUnitTree("SignedBy", ThisObject);
	
EndProcedure

&AtClient
Procedure SignedByChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"SignedBy", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure SignedByAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMUser", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure SignedByTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMUser", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"SignedBy", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Department

&AtClient
Procedure DepartmentStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheList("DMSubdivision", "Department", ThisObject);
	
EndProcedure

&AtClient
Procedure DepartmentChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Department", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure DepartmentAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
		StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMSubdivision", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure DepartmentTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
	StandardProcessing)
	
	DepartmentID = "";
	DepartmentType = "";
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMSubdivision", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Department", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure DepartmentClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	Department = "";
	DepartmentID = "";
	DepartmentType = "";
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// AccessBar

&AtClient
Procedure AccessBarStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheDropDownList(
		"DMAccessLevel", "AccessBar", ThisObject);
	
EndProcedure

&AtClient
Procedure AccessBarChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"AccessBar", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure AccessBarAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMAccessLevel", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure AccessBarTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMAccessLevel", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"AccessBar", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// QuestionOfActivity

&AtClient
Procedure QuestionOfActivityStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheList(
		"DMActivityMatter", "QuestionOfActivity", ThisObject);
	
EndProcedure

&AtClient
Procedure QuestionOfActivityChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"QuestionOfActivity", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure QuestionOfActivityAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
		StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMActivityMatter", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionOfActivityTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMActivityMatter", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"QuestionOfActivity", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Project

&AtClient
Procedure ProjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheList("DMProject", "Project", ThisObject);
	
EndProcedure

&AtClient
Procedure ProjectChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Project", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure ProjectAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMProject", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProjectTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMProject", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Project", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// State

&AtClient
Procedure StateListStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementClient.OpenDocumentStates(ThisObject);
	
EndProcedure

&AtClient
Procedure StateStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheDropDownList(
		"DMDocumentStatus", "State", ThisObject);
	
EndProcedure

&AtClient
Procedure StateChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"State", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure StateAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMDocumentStatus", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure StateTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMDocumentStatus", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"State", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// EmployeeResponsible

&AtClient
Procedure EmployeeResponsibleStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectUserFromUnitTree("EmployeeResponsible", ThisObject);
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"EmployeeResponsible", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMUser", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMUser", ChoiceData, Text, StandardProcessing);
		
		 If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"EmployeeResponsible", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Location

&AtClient
Procedure CaseFileNomenclatureStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementClient.OpenProductList(ThisObject);
	
EndProcedure

&AtClient
Procedure CaseFileNomenclatureClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	CaseFileNomenclature = "";
	CaseFileNomenclatureID = "";
	CaseFileNomenclatureType = "";
	CaseFileNomenclatureYear = 0;
	
EndProcedure

&AtClient
Procedure ToDoItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementClient.OpenDocumentStorageCase(ThisObject);
	
EndProcedure

&AtClient
Procedure ToDoItemClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	ToDoItem = "";
	ToDoItemID = "";
	ToDoItemType = "";
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Currency

&AtClient
Procedure CurrencyStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheDropDownList("DMCurrency", "Currency", ThisObject);
	
EndProcedure

&AtClient
Procedure CurrencyChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Currency", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure CurrencyAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMCurrency", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrencyTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMCurrency", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Currency", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// The composition of the document

&AtClient
Procedure CompositionStringStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementClient.OpenDocumentComposition(ThisObject);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Addressee

&AtClient
Procedure AddresseeStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectUserFromUnitTree("Addressee", ThisObject);
	
EndProcedure

&AtClient
Procedure AddresseeChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Addressee", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure AddresseeAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMUser", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure AddresseeTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMUser", ChoiceData, Text, StandardProcessing);
		
		 If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Addressee", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Prepared

&AtClient
Procedure PreparedStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectUserFromUnitTree("Prepared", ThisObject);
	
EndProcedure

&AtClient
Procedure PreparedChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Prepared", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure PreparedAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMUser", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure PreparedTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMUser", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Prepared", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Recipient

&AtClient
Procedure RecipientClearing(Item, StandardProcessing)
	
	Recipient = "";
	RecipientID = "";
	RecipientType = "";
	
EndProcedure

&AtClient
Procedure RecipientOnChange(Item)
	
	If Recipient = "" Then
		RecipientID = "";
		RecipientType = "";
	EndIf;
	
	Items.ExpenseReport.Visible = (RecipientType = "DMUser"
		Or IntegrationWith1CDocumentManagementCoreServerCall.TypeNameXDTO(RecipientType) = "DMUser");
	
EndProcedure

&AtClient
Procedure RecipientOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(RecipientID) Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(RecipientType, RecipientID, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure RecipientChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Recipient", ValueSelected.Value, StandardProcessing, ThisObject);
	
	Items.ExpenseReport.Visible = (RecipientType = "DMUser"
		Or IntegrationWith1CDocumentManagementCoreServerCall.TypeNameXDTO(RecipientType) = "DMUser");
	
EndProcedure

&AtClient
Procedure RecipientAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		AutomaticRecipientSelection(StandardProcessing, ChoiceData, Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure RecipientTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		AutomaticRecipientSelection(StandardProcessing, ChoiceData, Text);
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Recipient", ChoiceData[0].Value.Value, StandardProcessing, ThisObject);
			Items.ExpenseReport.Visible = (RecipientType = "DMUser"
				Or IntegrationWith1CDocumentManagementCoreServerCall.TypeNameXDTO(RecipientType) = "DMUser");
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure RecipientStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	TypesOfXDTO = New Array;
	TypesOfXDTO.Add("DMUser");
	TypesOfXDTO.Add("DMCorrespondent");
	AvailableTypeList = New ValueList;
	For Each XDTOType In TypesOfXDTO Do
		Presentation = IntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(XDTOType);
		AvailableTypeList.Add(
			New Structure("XDTOClassName, Presentation", XDTOType, Presentation));
	EndDo;
	
	FormCaption = NStr("vi = 'Kiểu người nhận';
						|ru = 'Тип получателя';
						|en = 'Recipient type'; fa = 'نوع گیرنده';
						|it = 'Tipo di destinatario';
						|pl = 'Rodzaj odbiorcy';
						|tr = 'Alıcı türü'");
	
	FormParameters = New Structure("AvailableTypeList, FormCaption",
		AvailableTypeList, FormCaption);
	Notification = New CallbackDescription("RecipientStartChoiceCompletion", ThisObject);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingOneTypeFromCompositeType",
		FormParameters,,,,, Notification);
	
EndProcedure

&AtClient
Procedure RecipientStartChoiceCompletion(TypeRecipient, Var_Parameters) Export
	
	If TypeRecipient = Undefined Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheList(
		TypeRecipient, "Recipient", ThisObject);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Counterparty

&AtClient
Procedure CounterpartyOnChange(Item)
	
	If Counterparty = "" Then
		CounterpartyID = "";
		CounterpartyType = "";
		
		ClearDocumentContacts();
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartyOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(CounterpartyID) Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject("DMCorrespondent", CounterpartyID, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartyStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheList("DMCorrespondent", "Counterparty", ThisObject);
	
EndProcedure

&AtClient
Procedure CounterpartyChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Counterparty", ValueSelected, StandardProcessing, ThisObject);
	
	ClearDocumentContacts();
	
EndProcedure

&AtClient
Procedure CounterpartyAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
		StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMCorrespondent", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartyTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
		StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMCorrespondent", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Counterparty", ChoiceData[0].Value, StandardProcessing, ThisObject);
			ClearDocumentContacts();
			StandardProcessing = True;
		EndIf;
	Else
		ClearDocumentContacts();
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// ContactPerson

&AtClient
Procedure ContactPersonOnChange(Item)
	
	If ContactPerson = "" Then
		ContactPersonID = "";
		ContactPersonType = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure ContactPersonStartChoice(Item, ChoiceData, StandardProcessing)
	
	If ValueIsFilled(CounterpartyID) Then
		
		Correspondent = New Structure;
		Correspondent.Insert("ID", CounterpartyID);
		Correspondent.Insert("type", "DMCorrespondent");
		
		Filter = New Structure;
		Filter.Insert("correspondent", Correspondent);
		
		IntegrationWith1CDocumentManagementClient.SelectAValueFromTheList(
			"DMContactPerson", "ContactPerson", ThisObject, Filter);
		
	Else
		MessageText = NStr("vi = 'Chưa điền trường ""Đối tác""';
							|ru = 'Не заполнено поле ""Контрагент""';
							|en = 'The field ""Counterparty"" is not filled in'; fa = 'The field ""Counterparty"" is not filled in';
							|it = 'Non è compilato il campo ""Contraente""';
							|pl = 'Nie wypełniono pole ""Kontrahent""';
							|tr = '""Cari hesap"" alanı doldurulmadı'");
		ShowMessageBox(, MessageText);
	EndIf;
	
EndProcedure

&AtClient
Procedure ContactPersonChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"ContactPerson", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure ContactPersonAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		AutoSelectionContactPerson(StandardProcessing, ChoiceData, Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure ContactPersonTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		AutoSelectionContactPerson(StandardProcessing, ChoiceData, Text);
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"ContactPerson", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Signed from the counterparty

&AtClient
Procedure SignedFromCounterpartyOnChange(Item)
	
	If SignedFromCounterparty = "" Then
		SignedFromCounterpartyID = "";
		SignedFromCounterpartyType = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure SignedFromCounterpartyStartChoice(Item, ChoiceData, StandardProcessing)
	
	If ValueIsFilled(CounterpartyID) Then
		
		Correspondent = New Structure;
		Correspondent.Insert("ID", CounterpartyID);
		Correspondent.Insert("type", "DMCorrespondent");
		
		Filter = New Structure;
		Filter.Insert("correspondent", Correspondent);
		
		IntegrationWith1CDocumentManagementClient.SelectAValueFromTheList(
			"DMContactPerson", "SignedFromCounterparty", ThisObject, Filter);
		
	Else
		MessageText = NStr("vi = 'Chưa điền trường ""Đối tác""';
							|ru = 'Не заполнено поле ""Контрагент""';
							|en = 'The field ""Counterparty"" is not filled in'; fa = 'The field ""Counterparty"" is not filled in';
							|it = 'Non è compilato il campo ""Contraente""';
							|pl = 'Nie wypełniono pole ""Kontrahent""';
							|tr = '""Cari hesap"" alanı doldurulmadı'");
		ShowMessageBox(, MessageText);
	EndIf;
	
EndProcedure

&AtClient
Procedure SignedFromCounterpartyChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"SignedFromCounterparty", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure SignedFromCounterpartyAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		AutoSelectionContactPerson(StandardProcessing, ChoiceData, Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure SignedFromCounterpartyTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		AutoSelectionContactPerson(StandardProcessing, ChoiceData, Text);
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"SignedFromCounterparty", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Expense report

&AtClient
Procedure ExpenseReportOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(ExpenseReportID) Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject("DMInternalDocument", ExpenseReportID, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpenseReportStartChoice(Item, ChoiceData, StandardProcessing)
	
	ContinueNotification = New CallbackDescription("ExpenseReportStartChoiceCompletion", ThisObject);
	
	IntegrationWith1CDocumentManagementClient.SelectValueByObjectType(
		ContinueNotification,
		"DMInternalDocument");
	
EndProcedure

&AtClient
Procedure ExpenseReportStartChoiceCompletion(SelectedDocument, Var_Parameters) Export
	
	If SelectedDocument = Undefined Then
		Return;
	EndIf;
	
	ExpenseReport = SelectedDocument.AttributePresentation;
	ExpenseReportID = SelectedDocument.AttributeID;
	ExpenseReportType = SelectedDocument.AttributeType;
	
EndProcedure

&AtClient
Procedure ExpenseReportClearing(Item, StandardProcessing)
	
	ExpenseReport = "";
	ExpenseReportID = "";
	ExpenseReportType = "";
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Folder

&AtClient
Procedure FolderOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(FolderType, FolderID, Item);
	
EndProcedure

&AtClient
Procedure FolderStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheList(
		"DMInternalDocumentFolder", "Folder", ThisObject);
	
EndProcedure

&AtClient
Procedure FolderChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Folder", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure FolderAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMInternalDocumentFolder", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure FolderTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
	StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMInternalDocumentFolder", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Folder", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// DDS articles, amount, VAT amount

&AtClient
Procedure PresentationOfCFItemsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenCFItems();
	
EndProcedure

&AtClient
Procedure PresentationOfCFItemsClearing(Item, StandardProcessing)
	
	CFItems.Clear();
	GeneratePresentationOfCFItems();
	
EndProcedure

&AtClient
Procedure PresentationOfCFItemsOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	OpenCFItems();
	
EndProcedure

&AtClient
Procedure PresentationOfCFItemsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	If TypeOf(ValueSelected) <> Type("Structure") Then
		Return;
	EndIf;
	
	CFItems.Clear();
	String = CFItems.Add();
	String.CFItem = ValueSelected.name;
	String.CFItemID = ValueSelected.ID;
	String.CFItemType = ValueSelected.type;
	
	String.Sum = Sum;
	String.VATAmount = VATAmount;
	
	GeneratePresentationOfCFItems();
	
EndProcedure

&AtClient
Procedure PresentationOfCFItemsAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMCashFlowItem", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure PresentationOfCFItemsTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMCashFlowItem", ChoiceData, Text, StandardProcessing);
			
		If ChoiceData.Count() = 1 Then
				
			StandardProcessing = True;
			
			CFItems.Clear();
			String = CFItems.Add();
			String.CFItem = ChoiceData[0].Value.name;
			String.CFItemID = ChoiceData[0].Value.ID;
			String.CFItemType = ChoiceData[0].Value.type;
			
			String.Sum = Sum;
			String.VATAmount = VATAmount;
			
			GeneratePresentationOfCFItems();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SumOnChange(Item)
	
	UpdateAmountDisplay();
	
EndProcedure

&AtClient
Procedure VATAmountOnChange(Item)
	
	UpdateDisplayOfVATAmount();
	
EndProcedure

&AtClient
Procedure DecorationChangeAmountClick(Item)
	
	OpenCFItems();
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// ValidityPeriodPresentation

&AtClient
Procedure ValidityPeriodPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementClient.OpenDocumentExpiration(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFiles

&AtClient
Procedure FilesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenFileForReading(Undefined);
	
EndProcedure

&AtClient
Procedure FilesOnActivateRow(Item)
	
	SetAvailabilityOfFileListCommands();
	
EndProcedure

&AtClient
Procedure FilesBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	OpenCard();
	
EndProcedure

&AtClient
Procedure FilesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	CreateFile(Undefined);
	
EndProcedure

&AtClient
Procedure FilesBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	If Items.Files.CurrentData = Undefined Then
		Return;
	EndIf;
	
	QueryText = "";
	
	If Items.Files.SelectedRows.Count() = 1 Then
		QueryText = StrTemplate(
			NStr("vi = 'Đặt dấu xóa ""%1""?';
				|ru = 'Пометить ""%1"" на удаление?';
				|en = 'Do you want to mark %1 for deletion?'; fa = 'Do you want to mark %1 for deletion?';
				|it = 'Contrassegnare ""%1"" per cancellazione?';
				|pl = 'Zaznaczyć ""%1"" do usunięcia?';
				|tr = '""%1"" silinmek üzere işaretlensin mi?'"), Items.Files.CurrentData.Description);
	Else
		QueryText = NStr("vi = 'Đặt dấu xóa các tệp đã chọn?';
						|ru = 'Пометить выделенные файлы на удаление?';
						|en = 'Mark selected files for deletion?'; fa = 'Mark selected files for deletion?';
						|it = 'Contrassegnare i file evidenziati per l''eliminazione?';
						|pl = 'Zaznaczyć wybrane pliki do usunięcia?';
						|tr = 'Seçilen dosyalar silinmek üzere işaretlensin mi?'");
	EndIf;
	
	AdditionalParameters = New Structure("SelectedRows", Items.Files.SelectedRows);
	Notification = New CallbackDescription("FilesBeforeDeleteRowCompletion", ThisObject, AdditionalParameters);
	
	IntegrationWith1CDocumentManagementClient.ShowQuestionYesNo(Notification, QueryText);
	
EndProcedure

&AtClient
Procedure FilesDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure FilesDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	FilesDragContinued(DragParameters);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProperties

&AtClient
Procedure PropertiesValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.SelectValueOfAdditionalProps(
		ThisObject,
		Item,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure PropertiesOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.Properties.CurrentData;
	If CurrentData.AvailableTypeList.Count() <> 1 Then
		Return;
	EndIf;
		
	If TypeOf(CurrentData.Value) = Type("String") Then
		XDTOType =CurrentData.AvailableTypeList[0].Value.xdtoClassName;
		If XDTOType = "integer" Then
			CurrentData.Value = 0;
		ElsIf XDTOType = "boolean" Then
			CurrentData.Value = False;
		ElsIf XDTOType = "date" Then
			CurrentData.Value = Date(1, 1, 1);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure PropertiesValueAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If Not ValueIsFilled(Text) Then
		Return;
	EndIf;
	
	CurrentData = Items.Properties.CurrentData;
	If CurrentData.AvailableTypeList.Count() <> 1 Then
		StandardProcessing = False;
		Return;
	EndIf;
		
	XDTOType = CurrentData.AvailableTypeList[0].Value.xdtoClassName;
	
	If XDTOType = "integer"
		Or XDTOType = "boolean"
		Or XDTOType = "date"
		Or XDTOType = "string" Then
		Return;
	EndIf;
		
	If XDTOType = "DMObjectPropertyValue" Then
		AdditionalProperty = New Structure;
		AdditionalProperty.Insert("ID", CurrentData.PropertyID);
		AdditionalProperty.Insert("type", CurrentData.PropertyType);
		Filter = New Structure("additionalProperty", AdditionalProperty);
	Else
		Filter = Undefined;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
		XDTOType, ChoiceData, Text, StandardProcessing, Filter);
	
EndProcedure

&AtClient
Procedure PropertiesValueTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If Not ValueIsFilled(Text) Then
		Return;
	EndIf;
	
	CurrentData = Items.Properties.CurrentData;
	If CurrentData.AvailableTypeList.Count() <> 1 Then
		StandardProcessing = False;
		Return;
	EndIf;
		
	XDTOType = CurrentData.AvailableTypeList[0].Value.xdtoClassName;
	
	If XDTOType = "integer"
		Or XDTOType = "boolean"
		Or XDTOType = "string"
		Or XDTOType = "date" Then
		Return;
	EndIf;
		
	If XDTOType = "DMObjectPropertyValue" Then
		AdditionalProperty = New Structure;
		AdditionalProperty.Insert("ID", CurrentData.PropertyID);
		AdditionalProperty.Insert("type", CurrentData.PropertyType);
		Filter = New Structure("additionalProperty", AdditionalProperty);
	Else
		Filter = Undefined;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
		XDTOType, ChoiceData, Text, StandardProcessing, Filter);
	
	If ChoiceData.Count() = 1 Then
		IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
			"Value", ChoiceData[0].Value, StandardProcessing, ThisObject, True, Item);
		StandardProcessing = True;
	EndIf;
		
EndProcedure

&AtClient
Procedure PropertiesValueChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Value", ValueSelected, StandardProcessing, ThisObject, True, Item);
		
EndProcedure

&AtClient
Procedure PropertiesValueClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	Items.Properties.CurrentData.Value = "";
	Items.Properties.CurrentData.ValueID = "";
	Items.Properties.CurrentData.ValueType = "";
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLinkTree

&AtClient
Procedure LinkTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.LinkTree.CurrentData;
	OpenRelatedRowData(CurrentData);
	
EndProcedure

&AtClient
Procedure LinkTreeOnActivateRow(Item)
	
	String = Item.CurrentData;
	
	OpeningAvailability =
		(String <> Undefined)
		And (String.Type <> "DMRelationType");
	AvailabilityOfDeletion = OpeningAvailability
		And (String.Type <> "DMFile");
		
	Items.LinkTreeOpen.Enabled = OpeningAvailability;
	Items.LinkTreeOpenContext.Enabled = OpeningAvailability;
	Items.LinkTreeDelete.Enabled = AvailabilityOfDeletion;
	Items.LinkTreeDeleteContext.Enabled = OpeningAvailability;
	
EndProcedure

&AtClient
Procedure LinkTreeBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure LinkTreeBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure LinkTreeBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	CurrentData = Items.LinkTree.CurrentData;
	If CurrentData = Undefined
		Or CurrentData.Type = "DMRelationType"
		Or CurrentData.Type = "DMFile" Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription(
		"StartDeletingLinkCompletion", ThisObject);
	
	LinkTypeString_ = CurrentData.GetParent();
	
	SourceDocument_ = New Structure("ID, Type, Presentation",
		ID, Type, Presentation);
	LinkedDocument = New Structure("ID, Type, Presentation",
		CurrentData.ID, CurrentData.Type, CurrentData.Title);
	LinkType = New Structure("ID, Type, Presentation",
		LinkTypeString_.ID, LinkTypeString_.Type, LinkTypeString_.Title);
	
	IntegrationWith1CDocumentManagementClient.StartDeletingLink(
		SourceDocument_,
		LinkedDocument,
		LinkType,
		CallbackDescription);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSignatureTable

&AtClient
Procedure SignatureTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementCoreClient.OpenSignature(Items.SignatureTable.CurrentData);
	
EndProcedure

&AtClient
Procedure SignatureTableOnActivateRow(Item)
	
	SetAvaliabilityOfDSCommandsList();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersVisaApprovals

&AtClient
Procedure VisaApprovalsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementClient.OpenVisa(
		ThisObject,
		Items.VisaApprovals.CurrentData);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnChange(Item)
	
	VATAmount = Goods.Total("VATAmount");
	UpdateDisplayOfVATAmount();
	
	Sum = Goods.Total("Sum");
	UpdateAmountDisplay();
	
	UpdatePageTitleProducts();
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Products

&AtClient
Procedure GoodsProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheListInTheTable(
		"DMProduct", "Products", Item.Parent.CurrentData, ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsProductsAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMProduct", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMProduct", ChoiceData, Text, StandardProcessing);
		If ChoiceData.Count() = 1 Then
			SelectItems(ChoiceData[0].Value, StandardProcessing, Item);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectItems(ValueSelected, StandardProcessing, Item);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Quantity, Price, Amount

&AtClient
Procedure GoodsCountOnChange(Item)
	
	WhenChangingProductsQuantity(Item.Parent.CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	WhenChangingProductsPrice(Item.Parent.CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	
	WhenChangingGoodsAmountOfVAT(Item.Parent.CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	WhenChangingGoodsAmount(Item.Parent.CurrentData);
	
EndProcedure


///////////////////////////////////////////////////////////////////////////////////////////////////
// Unit

&AtClient
Procedure GoodsUnitOfMeasureStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheListInTheTable(
		"DMMeasurementUnit", "UnitOfMeasure", Item.Parent.CurrentData, ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsUnitOfMeasureAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMMeasurementUnit", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsUnitOfMeasureTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching("DMMeasurementUnit", ChoiceData, Text, StandardProcessing);
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"UnitOfMeasure", ChoiceData[0].Value, StandardProcessing, ThisObject, True, Item);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsUnitOfMeasureChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"UnitOfMeasure", ValueSelected, StandardProcessing, ThisObject, True, Item);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// VAT rate

&AtClient
Procedure GoodsVATRateStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheDropDownList(
		"DMVATRate", "VATRate", ThisObject,, True, Item);
	
EndProcedure

&AtClient
Procedure GoodsVATRateAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMVATRate", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsVATRateTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching("DMVATRate", ChoiceData, Text, StandardProcessing);
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"VATRate", ChoiceData[0].Value, StandardProcessing, ThisObject, True, Item);
			StandardProcessing = True;
			
			WhenChangingGoodsVATRate(Item.Parent.CurrentData);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsVATRateChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"VATRate", ValueSelected, StandardProcessing, ThisObject, True, Item);
	
	WhenChangingGoodsVATRate(Item.Parent.CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	WhenChangingGoodsVATRate(Item.Parent.CurrentData);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersParties

&AtClient
Procedure PartiesOnChange(Item)
	
	TransferCounterpartyAndOrganizationFromPartySTsToDetails();
	
EndProcedure

&AtClient
Procedure PartiesBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.Parties.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurUserSigner = (CurrentData.SignedByID = CurrentUserBeforeID)
		And (CurrentData.SignedByType = CurrentUserBeforeType);
	CurUserSetSignature = (CurrentData.SetID = CurrentUserBeforeID)
		And (CurrentData.SetType = CurrentUserBeforeType);
	
	If CurrentData.PartyType = "DMOrganization"
		And CurrentData.Signed = True
		And ValueIsFilled(CurrentData.SignedBy)
		And ValueIsFilled(CurrentData.Set)
		And (Not CurUserSigner And Not CurUserSetSignature) Then
			Cancel = True;
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Party

&AtClient
Procedure PartiesPartyStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	TypesOfXDTO = New Array;
	TypesOfXDTO.Add("DMOrganization");
	TypesOfXDTO.Add("DMCorrespondent");
	AvailableTypeList = New ValueList;
	For Each XDTOType In TypesOfXDTO Do
		Presentation = IntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(XDTOType);
		AvailableTypeList.Add(
			New Structure("XDTOClassName, Presentation", XDTOType, Presentation));
	EndDo;
	
	FormCaption = NStr("vi = 'Kiểu bên';
						|ru = 'Тип стороны';
						|en = 'Party type'; fa = 'Party type';
						|it = 'Tipo di lato';
						|pl = 'Typ strony';
						|tr = 'Taraf türü'");
	
	FormParameters = New Structure("AvailableTypeList, FormCaption",
		AvailableTypeList, FormCaption);
	Notification = New CallbackDescription("PartiesPartyStartChoiceCompletion", ThisObject);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingOneTypeFromCompositeType",
		FormParameters,,,,, Notification);
	
EndProcedure

&AtClient
Procedure PartiesPartyStartChoiceCompletion(SideType, Var_Parameters) Export
	
	If SideType = Undefined Or Items.Parties.CurrentData = Undefined Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheListInTheTable(
		SideType, "Party", Items.Parties.CurrentData, ThisObject);
	
EndProcedure

&AtClient
Procedure PartiesPartyAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		AutoSideSelection(StandardProcessing, ChoiceData, Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure PartiesPartyTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		AutoSideSelection(StandardProcessing, ChoiceData, Text);
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Party", ChoiceData[0].Value.Value, StandardProcessing, ThisObject, True, Item.Parent);
			CleanTSSideContacts();
			FillInAdditionalData(
				Items.Parties.CurrentData,
				ChoiceData[0].Value.Value.type,
				ChoiceData[0].Value.Value.legalPrivatePersonID);
			StandardProcessing = True;
		EndIf;
	Else
		CleanTSSideContacts();
	EndIf;
	TransferCounterpartyAndOrganizationFromPartySTsToDetails();
	
EndProcedure

&AtClient
Procedure PartiesPartyClearing(Item, StandardProcessing)
	
	CleanTSSideContacts();
	TransferCounterpartyAndOrganizationFromPartySTsToDetails();
	
EndProcedure

&AtClient
Procedure PartiesPartyChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Party", ValueSelected.Value, StandardProcessing, ThisObject, True, Item.Parent);
	
	CleanTSSideContacts();
	FillInAdditionalData(
		Items.Parties.CurrentData,
		ValueSelected.Value.type,
		ValueSelected.Value.legalPrivatePersonID);
	TransferCounterpartyAndOrganizationFromPartySTsToDetails();
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Contact person

&AtClient
Procedure PartiesContactPersonStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Parties.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.PartyType = "DMOrganization" Then
		IntegrationWith1CDocumentManagementClient.SelectAValueFromTheListInTheTable(
			"DMUser", "ContactPerson", Items.Parties.CurrentData, ThisObject);
		
	ElsIf CurrentData.PartyType = "DMCorrespondent" Then
		Correspondent = New Structure;
		Correspondent.Insert("ID", CurrentData.PartyID);
		Correspondent.Insert("type", "DMCorrespondent");
		
		Filter = New Structure;
		Filter.Insert("correspondent", Correspondent);
		
		IntegrationWith1CDocumentManagementClient.SelectAValueFromTheListInTheTable(
			"DMContactPerson", "ContactPerson", CurrentData, ThisObject, Filter);
		
	Else
		MessageText = NStr("vi = 'Chưa điền trường ""Bên""';
							|ru = 'Не заполнено поле ""Сторона""';
							|en = 'The ""Party"" field is not filled in'; fa = 'The ""Party"" field is not filled in';
							|it = 'Campo ""Lato"" non compilato';
							|pl = 'Nie wypełnione pole ""Strona""';
							|tr = '""Taraf"" alanı doldurulmadı'");
		ShowMessageBox(, MessageText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PartiesContactPersonChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"ContactPerson", ValueSelected, StandardProcessing, ThisObject, True, Item.Parent);
	
EndProcedure

&AtClient
Procedure PartiesContactPersonAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		AutoSelectionTSPartyContactPerson(StandardProcessing, ChoiceData, Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure PartiesContactPersonTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		AutoSelectionTSPartyContactPerson(StandardProcessing, ChoiceData, Text);
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"ContactPerson", ChoiceData[0].Value, StandardProcessing, ThisObject, True, Item.Parent);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Name of the party

&AtClient
Procedure PartiesDescriptionStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.Parties.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheListInTheTable(
		"DMPartyName", "Description", Items.Parties.CurrentData, ThisObject);
	
EndProcedure

&AtClient
Procedure PartiesDescriptionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Description", ValueSelected, StandardProcessing, ThisObject, True, Item.Parent);
	
EndProcedure

&AtClient
Procedure PartiesDescriptionAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMPartyName", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure PartiesDescriptionTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMPartyName", ChoiceData, Text, StandardProcessing);
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Description", ChoiceData[0].Value, StandardProcessing, ThisObject, True, Item.Parent);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// SignedBy

&AtClient
Procedure PartiesSignedByStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Parties.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.PartyType = "DMOrganization" Then
		IntegrationWith1CDocumentManagementClient.SelectAValueFromTheListInTheTable(
			"DMUser", "SignedBy", Items.Parties.CurrentData, ThisObject);
		
	ElsIf CurrentData.PartyType = "DMCorrespondent" Then
		Correspondent = New Structure;
		Correspondent.Insert("ID", CurrentData.PartyID);
		Correspondent.Insert("type", "DMCorrespondent");
		
		Filter = New Structure;
		Filter.Insert("correspondent", Correspondent);
		
		IntegrationWith1CDocumentManagementClient.SelectAValueFromTheListInTheTable(
			"DMContactPerson", "SignedBy", CurrentData, ThisObject, Filter);
		
	Else
		MessageText = NStr("vi = 'Chưa điền trường ""Bên""';
							|ru = 'Не заполнено поле ""Сторона""';
							|en = 'The ""Party"" field is not filled in'; fa = 'The ""Party"" field is not filled in';
							|it = 'Campo ""Lato"" non compilato';
							|pl = 'Nie wypełnione pole ""Strona""';
							|tr = '""Taraf"" alanı doldurulmadı'");
		ShowMessageBox(, MessageText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PartiesSignedByChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"SignedBy", ValueSelected, StandardProcessing, ThisObject, True, Item.Parent);
	
EndProcedure

&AtClient
Procedure PartiesSignedByAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		AutoSelectionTSPartyContactPerson(StandardProcessing, ChoiceData, Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure PartiesSignedByTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		AutoSelectionTSPartyContactPerson(StandardProcessing, ChoiceData, Text);
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"SignedBy", ChoiceData[0].Value, StandardProcessing, ThisObject, True, Item.Parent);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCounterparties

&AtClient
Procedure CounterpartiesOnChange(Item)
	
	UpdatePageTitleCounterparties();
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Counterparty

&AtClient
Procedure CounterpartiesCounterpartyStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheListInTheTable(
		"DMCorrespondent", "Counterparty", Items.Counterparties.CurrentData, ThisObject);
	
EndProcedure

&AtClient
Procedure CounterpartiesCounterpartyChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Counterparty", ValueSelected, StandardProcessing, ThisObject, True, Item);
	
	ClearContactsTSCounterparties();
	
EndProcedure

&AtClient
Procedure CounterpartiesCounterpartyAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMCorrespondent", ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartiesCounterpartyTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMCorrespondent", ChoiceData, Text, StandardProcessing);
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Counterparty", ChoiceData[0].Value, StandardProcessing, ThisObject, True, Item);
			ClearContactsTSCounterparties();
			StandardProcessing = True;
		EndIf;
	Else
		ClearContactsTSCounterparties();
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Signed from the counterparty

&AtClient
Procedure CounterpartiesSignedFromCounterpartyChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"SignedFromCounterparty", ValueSelected, StandardProcessing, ThisObject, True, Item);
	
EndProcedure

&AtClient
Procedure CounterpartiesSignedFromCounterpartyAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		AutoSelectionContactPersonTSContractors(StandardProcessing, ChoiceData, Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartiesSignedFromCounterpartyTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		AutoSelectionContactPersonTSContractors(StandardProcessing, ChoiceData, Text);
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"SignedFromCounterparty", ChoiceData[0].Value, StandardProcessing, ThisObject, True, Item);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartiesSignedFromCounterpartyStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Counterparties.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.Counterparty) Then
		Correspondent = New Structure;
		Correspondent.Insert("ID", CurrentData.CounterpartyID);
		Correspondent.Insert("type", "DMCorrespondent");
		
		Filter = New Structure;
		Filter.Insert("correspondent", Correspondent);
		
		IntegrationWith1CDocumentManagementClient.SelectAValueFromTheListInTheTable(
			"DMContactPerson", "SignedFromCounterparty", CurrentData, ThisObject, Filter);
		
	Else
		MessageText = NStr("vi = 'Chưa điền trường ""Đối tác""';
							|ru = 'Не заполнено поле ""Контрагент""';
							|en = 'The field ""Counterparty"" is not filled in'; fa = 'The field ""Counterparty"" is not filled in';
							|it = 'Non è compilato il campo ""Contraente""';
							|pl = 'Nie wypełniono pole ""Kontrahent""';
							|tr = '""Cari hesap"" alanı doldurulmadı'");
		ShowMessageBox(, MessageText);
		
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Contact person

&AtClient
Procedure CounterpartiesContactPersonChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"ContactPerson", ValueSelected, StandardProcessing, ThisObject, True, Item);
	
EndProcedure

&AtClient
Procedure CounterpartiesContactPersonAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		AutoSelectionContactPersonTSContractors(StandardProcessing, ChoiceData, Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartiesContactPersonTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		AutoSelectionContactPersonTSContractors(StandardProcessing, ChoiceData, Text);
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"ContactPerson", ChoiceData[0].Value, StandardProcessing, ThisObject, True, Item);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartiesContactPersonStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Counterparties.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.Counterparty) Then
		Correspondent = New Structure;
		Correspondent.Insert("ID", CurrentData.CounterpartyID);
		Correspondent.Insert("type", "DMCorrespondent");
		
		Filter = New Structure;
		Filter.Insert("correspondent", Correspondent);
		
		IntegrationWith1CDocumentManagementClient.SelectAValueFromTheListInTheTable(
			"DMContactPerson", "ContactPerson", CurrentData, ThisObject, Filter);
		
	Else
		MessageText = NStr("vi = 'Chưa điền trường ""Đối tác""';
							|ru = 'Не заполнено поле ""Контрагент""';
							|en = 'The field ""Counterparty"" is not filled in'; fa = 'The field ""Counterparty"" is not filled in';
							|it = 'Non è compilato il campo ""Contraente""';
							|pl = 'Nie wypełniono pole ""Kontrahent""';
							|tr = '""Cari hesap"" alanı doldurulmadı'");
		ShowMessageBox(, MessageText);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

///////////////////////////////////////////////////////////////////////////////////////////////////
// Overall

&AtClient
Procedure WriteDocument(Command)
	
	RecordAndPossiblyClose(False);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	RecordAndPossiblyClose(True);
	
EndProcedure

&AtClient
Procedure Register(Command)
	
	Notification = New CallbackDescription("RegisterCompletion", ThisObject);
	
	If RestrictAvailabilityOfFields Then
		
		QueryText = NStr(
			"vi = 'Sau khi đăng ký, chứng từ sẽ không thể thay đổi.
			|Tiếp tục?';
			|ru = 'После регистрации документ станет недоступным для изменения.
			|Продолжить?';
			|en = 'After the document is registered, you cannot modify it.
			|Continue?'; fa = 'After the document is registered, you cannot modify it.
			|Continue?';
			|it = 'Dopo la registrazione il documento non potrà più essere modificato.
			|Continuare?';
			|pl = 'Po rejestracji dokument zostanie stanie się niedostępny do zmiany.
			|Kontynuować?';
			|tr = 'Kayıttan sonra, belge düzenleme için erişilemez hale gelecektir.
			|Devam et?'");
		IntegrationWith1CDocumentManagementClient.ShowQuestionYesNo(
			Notification,
			QueryText,
			IntegrationWith1CDocumentManagementCoreClient.QuestionParametersYesNo(DialogReturnCode.Yes));
		
	Else
		
		RunCallback(Notification, DialogReturnCode.Yes);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SpecifyLaborCosts(Command)
	
	FormParameters = New Structure;
	
	FormParameters.Insert("Source", Presentation);
	FormParameters.Insert("SourceID", ID);
	FormParameters.Insert("SourceType", Type);
	
	If ValueIsFilled(ExternalObject) Then
		FormParameters.Insert("ExternalObject", ExternalObject);
	EndIf;
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.InsertWork", FormParameters, ID);
	
EndProcedure

&AtClient
Procedure SwitchTiming(Command)
	
	NeedDialogue = True;
	WorkDuration =
		IntegrationWith1CDocumentManagementClient.GetRunningTime(StartDateOfTimekeeping);
	If WorkDuration < 60 Then // Less than 1 minute - we do not ask for details.
		NeedDialogue = False;
	EndIf;
	
	If NeedDialogue Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Source", Presentation);
		FormParameters.Insert("SourceID", ID);
		FormParameters.Insert("SourceType", Type);
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.InsertWork", FormParameters, ID);
		
	Else // Let's write it down silently.
		
		If TimekeepingEnabled Then
			SwitchTimingServer();
			If TimekeepingEnabled Then
				Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Sử dụng đồng hồ tính thời gian theo ""%1""';
						|ru = 'Включен хронометраж по ""%1""';
						|en = 'Timing by ""%1"" is enabled'; fa = 'Timing by ""%1"" is enabled';
						|it = 'Crono-analisi attivata per ""%1""';
						|pl = 'Chronometraż jest włączony według ""%1""';
						|tr = '""%1"" ile kronometre etkin'"), String(Presentation));
				Status(Text);
			EndIf;
		Else
			ActiveEntries = IntegrationWith1CDocumentManagementServerCall.ActiveTimekeepingRecords();
			If ActiveEntries.Count() = 0 Then
				SwitchTimingServer();
				If TimekeepingEnabled Then
					Text = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Sử dụng đồng hồ tính thời gian theo ""%1""';
							|ru = 'Включен хронометраж по ""%1""';
							|en = 'Timing by ""%1"" is enabled'; fa = 'Timing by ""%1"" is enabled';
							|it = 'Crono-analisi attivata per ""%1""';
							|pl = 'Chronometraż jest włączony według ""%1""';
							|tr = '""%1"" ile kronometre etkin'"), String(Presentation));
					Status(Text);
				EndIf;
			Else
				NotificationParameters = New Structure;
				NotificationParameters.Insert("ActiveEntries", ActiveEntries);
				
				Notification = New CallbackDescription(
					"SwitchTimingCompletion", ThisObject, NotificationParameters);
					
				StringOfTimekeepingObjects = "";
				For Each Record In ActiveEntries Do
					StringOfTimekeepingObjects = StringOfTimekeepingObjects + Chars.Tab
						+ Record.Source + Chars.LF;
				EndDo;
				
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Sử dụng đồng hồ tính thời gian theo các đối tượng khác nhau:
						|%1
						|Tắt đồng hồ tính thời gian và ghi nhận công lao động
						|trước khi sử dụng đồng hồ tính thời gian mới?';
						|ru = 'Включен хронометраж по другим объектам:
						|%1
						|Отключить хронометраж и зафиксировать трудозатраты
						|перед включением нового хронометража?';
						|en = 'Timing by other objects is enabled:
						|%1
						|Disable timing and record labor costs 
						|before enabling new timing?'; fa = 'Timing by other objects is enabled:
						|%1
						|Disable timing and record labor costs 
						|before enabling new timing?';
						|it = 'Crono-analisi attivata per altri oggetti:
						|%1
						|Disattivare la crono-analisi e bloccare il costo del lavoro
						|prima di attivare la nuova crono-analisi?';
						|pl = 'Chronometraż jest włączony według innych obiektów:
						|%1
						|Wyłączyć chronometraż i ustalić nakłady pracy przed
						|włączeniem nowego chronometrażu?';
						|tr = 'Diğer nesneler için kronometraj etkinleştirildi:
						|%1
						|Yeni kronometrajı etkinleştirmeden
						|önce kronometraj devre dışı bırakılsın ve iş gücü maliyetleri uygulansın mı?'"),
						StringOfTimekeepingObjects);
						
				Buttons = New ValueList;
				Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Có';
														|ru = 'Да';
														|en = 'Yes'; fa = 'بله';
														|it = 'Sì';
														|pl = 'Yes';
														|tr = 'Evet'"));
				Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
															|ru = 'Отмена';
															|en = 'Cancel'; fa = 'انصراف';
															|it = 'Annulla';
															|pl = 'Cancel';
															|tr = 'İptal'"));
				
				ShowQueryBox(Notification, QueryText, Buttons,, DialogReturnCode.Cancel);
				
			EndIf;
				
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Send(Command)
	
	If ValueIsFilled(ID) Then
		
		IntegrationWith1CDocumentManagementClient.CreateABusinessProcessByTheObjectDM(ID, Type, Description, ExternalObject);
		
	Else
		
		Notification = New CallbackDescription("CreateBusinessProcessCompletion", ThisObject);
		RecordAndPossiblyClose(False, Notification);
		
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Links

// Starts adding the linked document.
&AtClient
Procedure AddLink(Command)
	
	If IsBlankString(ID) Then
		WriteObject(False);
		IntegrationWith1CDocumentManagementClient.Notify_DocumentEntry(ThisObject);
	EndIf;
	
	Filter = New Structure;
	If ValueIsFilled(CounterpartyID) Then
		Condition = New Structure;
		Condition.Insert("Value", Counterparty);
		Condition.Insert("ValueID", CounterpartyID);
		Filter.Insert("correspondent", Condition);
	EndIf;
	If ValueIsFilled(OrganizationID) Then
		Condition = New Structure;
		Condition.Insert("Value", Organization);
		Condition.Insert("ValueID", OrganizationID);
		Filter.Insert("organization", Condition);
	EndIf;
	
	CallbackDescription = New CallbackDescription(
		"StartAddingLinkCompletion", ThisObject);
	IntegrationWith1CDocumentManagementClient.StartAddingLink(
		ID, Type, Presentation,, CallbackDescription, Filter);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure OpenRelatedData(Command)
	
	String = Items.LinkTree.CurrentData;
	If String <> Undefined Then
		OpenRelatedRowData(String);
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Files

&AtClient
Async Procedure CreateFile(Val Command)
	
	YouNeedToAddScannedCopy =
		Await IntegrationWith1CDocumentManagementCoreClient.YouNeedToAddScannedCopyAsync(
			StateAllowsAddingScannedCopy,
			StateAllowsFileAddition);
	
	If YouNeedToAddScannedCopy = DialogReturnCode.Yes Then
		If IsBlankString(ID) Then
			WriteObject();
			IntegrationWith1CDocumentManagementClient.Notify_DocumentEntry(ThisObject);
		EndIf;
		IntegrationWith1CDocumentManagementCoreClient.CreateFileFromDisk(FileCreationStartParameters());
	EndIf;
	
EndProcedure

&AtClient
Procedure AddPrintedForm(Command)
	
	If Not ValueIsFilled(ExternalObject) Then
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trước khi thêm mẫu in, cần liên kết
				|văn bản nội bộ với đối tượng %1';
				|ru = 'Перед добавлением печатной формы нужно связать
				|внутренний документ с объектом %1';
				|en = 'Link the internal document with the %1 object
				|before adding a print form'; fa = 'Link the internal document with the %1 object
				|before adding a print form';
				|it = 'Prima dell''aggiunta della forma di stampa è necessario collegare
				|il documento interno con l''oggetto %1';
				|pl = 'Przed dodawaniem formularza wydruku należy powiązać
				|dokument wewnętrzny z obiektem %1';
				|tr = 'Yazdırılabilir belge eklemeden önce, 
				|dahili bir belgeyi nesneyle ilişkilendirmeniz gerekir %1'"), AbbreviatedNameOfConfiguration);
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	If IsBlankString(ID) Then
		WriteObject();
		IntegrationWith1CDocumentManagementClient.Notify_DocumentEntry(ThisObject);
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ObjectIS", ExternalObject);
	FormParameters.Insert("ObjectIDDM", ID);
	FormParameters.Insert("ObjectTypeDM", Type);
	
	CallbackDescription = New CallbackDescription("InsertPrintFormCompletion", ThisObject);
	
	AdditionForm = OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.InsertPrintForm",
		FormParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockWholeInterface);
	
	If AdditionForm = Undefined Then
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 không có mẫu in.';
				|ru = '%1 не имеет печатных форм.';
				|en = '%1 has no print forms.'; fa = '%1 has no print forms.';
				|it = '%1 non possiede forme di stampa.';
				|pl = '%1 nie ma formularzy wydruku.';
				|tr = '%1 yazdırılabilir formları mevcut değil.'"), String(ExternalObject));
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillFilesByCopying(Command)
	
	Mode = New ValueList;
	Mode.Add(DialogReturnCode.Yes, NStr("vi = 'Điền';
										|ru = 'Заполнить';
										|en = 'Fill in'; fa = 'پرکردن';
										|it = 'Compilare';
										|pl = 'Fill in';
										|tr = 'Doldur'"));
	Mode.Add(DialogReturnCode.No, NStr("vi = 'Không điền';
										|ru = 'Не заполнять';
										|en = 'Do not fill in'; fa = 'پر نشود';
										|it = 'Non compilare';
										|pl = 'Nie wypełniaj';
										|tr = 'Doldurma'"));
	
	Notification = New CallbackDescription("FillFilesByCopyingCompletion", ThisObject);
	QueryText =  NStr("vi = 'Điền tệp bằng cách sao chép từ các tệp đính kèm?';
						|ru = 'Заполнить файлы копированием из присоединенных файлов?';
						|en = 'Populate files by copying from the attached files?'; fa = 'Populate files by copying from the attached files?';
						|it = 'Compilare i file copiando da i dati allegati?';
						|pl = 'Wypełnić pliki kopiowaniem z załączonych plików?';
						|tr = 'Ekli dosyalardan kopyalayarak dosyalar doldurulsun mu?'");
	
	ShowQueryBox(Notification, QueryText, Mode,, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure OpenFileForReading(Command)
	
	If IsBlankString(ID) Then
		WriteObject();
		IntegrationWith1CDocumentManagementClient.Notify_DocumentEntry(ThisObject);
	EndIf;
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData <> Undefined Then
		IntegrationWith1CDocumentManagementCoreClient.OpenFile(
			CurrentData.ID,
			CurrentData.Description,
			CurrentData.Extension,
			UUID);
	EndIf;

EndProcedure

&AtClient
Procedure OpenFileForEditing(Command)
	
	If IsBlankString(ID) Then
		WriteObject();
		IntegrationWith1CDocumentManagementClient.Notify_DocumentEntry(ThisObject);
	EndIf;
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData <> Undefined Then
		CallbackDescription = New CallbackDescription("EditingCommandsCompletion", ThisObject);
		IntegrationWith1CDocumentManagementCoreClient.OpenFile(
			CurrentData.ID,
			CurrentData.Description,
			CurrentData.Extension,
			UUID,
			False,
			CallbackDescription);
	EndIf;
	
EndProcedure

&AtClient
Procedure EndFileEditing(Command)
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData <> Undefined Then
		CallbackDescription = New CallbackDescription("EditingCommandsCompletion", ThisObject);
		IntegrationWith1CDocumentManagementCoreClient.EndFileEditing(
			CurrentData.ID,
			CurrentData.Description,
			CurrentData.Extension,
			UUID,
			CallbackDescription);
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveFileToDisk(Command)
	
	If IsBlankString(ID) Then
		WriteObject();
		IntegrationWith1CDocumentManagementClient.Notify_DocumentEntry(ThisObject);
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.StartSavingSelectedFiles(
		Files,
		Items.Files.SelectedRows,
		UUID);
	
EndProcedure

&AtClient
Procedure UpdateFromFileOnHardDrive(Command)
	
	If IsBlankString(ID) Then
		WriteObject();
		IntegrationWith1CDocumentManagementClient.Notify_DocumentEntry(ThisObject);
	EndIf;
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData <> Undefined Then
		CallbackDescription = New CallbackDescription("EditingCommandsCompletion", ThisObject);
		IntegrationWith1CDocumentManagementCoreClient.UpdateFromFileOnHardDrive(
			CurrentData.ID,
			CurrentData.Description,
			CurrentData.Extension,
			ToLocalTime(CurrentData.UniversalModificationDate),
			UUID,
			CallbackDescription);
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveFileChanges(Command)
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData <> Undefined Then
		CallbackDescription = New CallbackDescription("EditingCommandsCompletion", ThisObject);
		IntegrationWith1CDocumentManagementCoreClient.SaveChangesToEditedFile(
			CurrentData.ID,
			CurrentData.Description,
			CurrentData.Extension,
			UUID,
			CallbackDescription);
	EndIf;
	
EndProcedure

&AtClient
Procedure UndoFileEditing(Command)
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData <> Undefined Then
		CallbackDescription = New CallbackDescription("EditingCommandsCompletion", ThisObject);
		IntegrationWith1CDocumentManagementCoreClient.UndoFileEditing(
			CurrentData.ID,
			CallbackDescription,,
			UUID);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillFileWithDocumentData(Command)
	
	If IsBlankString(ID) Then
		WriteObject();
		IntegrationWith1CDocumentManagementClient.Notify_DocumentEntry(ThisObject);
	EndIf;
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData <> Undefined Then
		IntegrationWith1CDocumentManagementCoreServerCall.FillFileFieldsWithOwnerData(
			CurrentData.ID);
		Text = NStr("vi = 'Đã cập nhật các trường trong dữ liệu bằng dữ liệu của đối tượng chủ.';
					|ru = 'Поля в файле обновлены данными владельца.';
					|en = 'Fields in the file are updated with user data.'; fa = 'Fields in the file are updated with user data.';
					|it = 'I campi nel file sono stati aggiornati con i dati del proprietario.';
					|pl = 'Pola w pliku są aktualizowane danymi właściciela.';
					|tr = 'Dosyadaki alanlar, sahip verileriyle güncellendi.'");
		ShowMessageBox(, Text);
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Files (EP)

&AtClient
Procedure SignFile(Command)
	
	If Items.Files.CurrentData = Undefined Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("SignFileCompletion", ThisObject, Undefined);
	If IsBlankString(ID) Then
		RecordAndPossiblyClose(False, Notification);
	Else
		RunCallback(Notification, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure SignFileCompletion(Result, NotificationParameters) Export
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SignatureTable = IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable(
		SignatureTree,,
		CurrentData.ID);
	
	FileProperties = IntegrationWith1CDocumentManagementCoreClientServer.FileProperties();
	FileProperties.FileID = CurrentData.ID;
	FileProperties.FileName = CurrentData.Description;
	FileProperties.FileOwner = ID;
	FileProperties.IsBeingEdited = CurrentData.IsBeingEdited;
	FileProperties.Encrypted = CurrentData.Encrypted;
	FileProperties.FileDetails = CurrentData.LongDesc;
	FileProperties.FormUniqueID = UUID;
	FileProperties.FileSignatureData =
		IntegrationWith1CDocumentManagementCoreClient.DataOfSignatures(SignatureTable);
	
	IntegrationWith1CDocumentManagementCoreClient.SignFile(FileProperties);
	
EndProcedure

&AtClient
Procedure AddDSFromFile(Command)
	
	CurrentData = Items.Files.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FileID = CurrentData.ID;
	SignatureTable = IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable(
		SignatureTree,,
		FileID);
	FileSignatureData = IntegrationWith1CDocumentManagementCoreClient.DataOfSignatures(SignatureTable);
	
	FileProperties = IntegrationWith1CDocumentManagementCoreClientServer.FileProperties();
	FileProperties.FileID = FileID;
	FileProperties.FileName = CurrentData.Description;
	FileProperties.FileDetails = CurrentData.LongDesc;
	FileProperties.IsBeingEdited = CurrentData.IsBeingEdited;
	FileProperties.Encrypted = CurrentData.Encrypted;
	FileProperties.FileSignatureData = FileSignatureData;
	FileProperties.FormUniqueID = UUID;
	FileProperties.FileOwner = ID;
	
	IntegrationWith1CDocumentManagementCoreClient.StartAddingItemsFromFile(FileProperties);
	
EndProcedure

&AtClient
Procedure SaveFileTogetherBOT(Command)
	
	CurrentData = Items.Files.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FileID = CurrentData.ID;
	Extension = CurrentData.Extension;
	Name = CurrentData.Description;
	Size = CurrentData.Size * 1024; // convert from KB to bytes
	UniversalModificationDate = CurrentData.UniversalModificationDate;
	
	IntegrationWith1CDocumentManagementCoreClient.StartSavingTogetherBOT(
		FileID,
		Extension,
		Name,
		Size,
		UniversalModificationDate,
		UUID);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// DS

&AtClient
Procedure SignDocument(Command)
	
	If IsBlankString(ID) Then
		Notification = New CallbackDescription("SignDocumentCompletion", ThisObject);
		RecordAndPossiblyClose(False, Notification);
	Else
		SetSignatures_();
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSignature(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.OpenSignature(Items.SignatureTable.CurrentData);
	
EndProcedure

&AtClient
Procedure SaveSignatureToDisk(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.SaveSignature(Items.SignatureTable.CurrentData);
	
EndProcedure

&AtClient
Procedure VerifySignature(Command)
	
	SelectedSignatures = IntegrationWith1CDocumentManagementCoreClient.SelectedSignatures(
		Items.SignatureTable.SelectedRows,
		SignatureTree);
	SignatureTable = IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable(SignatureTree);
	
	Notification = New CallbackDescription("VerifySignatureCompletion", ThisObject);
	IntegrationWith1CDocumentManagementCoreClient.VerifySignatures(
		SignatureTable,
		AddressOfObjectSBinaryData,
		Notification,
		SelectedSignatures);
	
EndProcedure

&AtClient
Procedure CheckAllSignatures(Command)
	
	SignatureTable = IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable(SignatureTree);
	
	Notification = New CallbackDescription("VerifySignatureCompletion", ThisObject);
	IntegrationWith1CDocumentManagementCoreClient.VerifySignatures(
		SignatureTable,
		AddressOfObjectSBinaryData,
		Notification);
	
EndProcedure

&AtClient
Procedure VerifySignatureCompletion(Result, NotificationParameters) Export
	
	IntegrationWith1CDocumentManagementCoreClient.SetStatusOfSignatures(SignatureTree, Result);
	
EndProcedure

&AtClient
Procedure DeleteSignature(Command)
	
	SelectedSignatures = IntegrationWith1CDocumentManagementCoreClient.SelectedSignatures(
		Items.SignatureTable.SelectedRows,
		SignatureTree);
	SignatureTable = IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable(SignatureTree);
	
	Notification = New CallbackDescription("DeleteSignatureCompletion", ThisObject);
	IntegrationWith1CDocumentManagementCoreClient.DeleteSignatures(
		SelectedSignatures,
		SignatureTable,
		ID,
		Notification,
		UUID);
	
EndProcedure

// Completes signature deletion after user confirmation.
//
&AtClient
Procedure DeleteSignatureCompletion(Result, NotificationParameters) Export
	
	If Result <> True Then
		Return;
	EndIf;
	
	ReadAndUpdateListOfSignatures();
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Counterparties

&AtClient
Procedure ManyCounterparties(Command)
	
	MultipleCounterparties = True;
	UpdateTablePartCounterparties();
	SetCounterpartyVisibility();

	Items.GroupPages.CurrentPage = Items.CounterpartiesPage;
	
EndProcedure

&AtClient
Procedure OneCounterparty(Command)
	
	CounterpartiesCount = Counterparties.Count();
	For Indus = 1 To CounterpartiesCount Do
		String = Counterparties[CounterpartiesCount - Indus];
		If Not ValueIsFilled(String.Counterparty) Then
			Counterparties.Delete(String);
		EndIf;
	EndDo;
	CounterpartiesCount = Counterparties.Count();
	
	CallbackDescription = New CallbackDescription(
		"OneCounterpartyContinued",
		ThisObject,
		New Structure("CounterpartiesCount", CounterpartiesCount));
	
	If CounterpartiesCount > 1 Then
		QueryText = NStr("vi = 'Tất cả đối tác, ngoại trừ đối tác đầu tiên, sẽ bị xóa.
			|Tiếp tục?';
			|ru = 'Все контрагенты, кроме первого, будут удалены.
			|Продолжить?';
			|en = 'All counterparties except for the first one will be deleted.
			|Continue?'; fa = 'All counterparties except for the first one will be deleted.
			|Continue?';
			|it = 'Tutte le controparti, tranne la prima, saranno eliminate.
			|Continuare?';
			|pl = 'Wszystkie kontrahenci, oprócz pierwszego, będą usunięte.
			|Kontynuować?';
			|tr = 'İlki hariç tüm cari hesaplar silinecektir.
			|Devam et?'");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		RunCallback(CallbackDescription, DialogReturnCode.Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure OneCounterpartyContinued(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.No Then
		Return;
		
	ElsIf Result = DialogReturnCode.Yes Then
		While Counterparties.Count() > 1 Do
			Counterparties.Delete(1);
		EndDo;
		Modified = True;
		
	EndIf;
	
	If Var_Parameters.CounterpartiesCount > 0 Then
		String = Counterparties[0];
		Counterparty = String.Counterparty;
		CounterpartyID = String.CounterpartyID;
		CounterpartyType = String.CounterpartyType;
		ContactPerson = String.ContactPerson;
		ContactPersonID = String.ContactPersonID;
		ContactPersonType = String.ContactPersonType;
		SignedFromCounterparty = String.SignedFromCounterparty;
		SignedFromCounterpartyID = String.SignedFromCounterpartyID;
		SignedFromCounterpartyType = String.SignedFromCounterpartyType;
	Else
		Counterparty = "";
		CounterpartyID = "";
		CounterpartyType = "";
		ClearDocumentContacts();
	EndIf;
	
	MultipleCounterparties = False;
	SetCounterpartyVisibility();
	
	Items.GroupPages.CurrentPage = Items.BankingDetailsPage;
	
EndProcedure

#EndRegion

#Region Private

///////////////////////////////////////////////////////////////////////////////////////////////////
// Closing and recording

// Called before closing after the user answers the question "Write?"
//
&AtClient
Procedure BeforeCloseCompletion(Response, NotificationParameters) Export
	
	WriteObject();
	IntegrationWith1CDocumentManagementClient.Notify_DocumentEntry(ThisObject);
	CloseWithParameter();
	
EndProcedure

// It is called before recording and, if necessary, asks a question about the consequences of registration.
//
// Parameters:
//   CloseAfterWrite - Boolean - True if the form should be closed after recording.
//   NotificationAfterRecording - CallbackDescription - optional, a handler called after recording.
//
&AtClient
Procedure RecordAndPossiblyClose(CloseAfterWrite, NotificationAfterRecording = Undefined)
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("CloseAfterWrite", CloseAfterWrite);
	NotificationParameters.Insert("NotificationAfterRecording", NotificationAfterRecording);
	
	Notification = New CallbackDescription(
		"RecordAndPossiblyCloseCompletion",
		ThisObject,
		NotificationParameters);
	
	If RestrictAvailabilityOfFields
			And ValueIsFilled(RegistrationNumber)
			And Not ValueIsFilled(InitialRegistrationNumber) Then
		
		QueryText = NStr(
			"vi = 'Khi ghi lại, chứng từ sẽ được đăng ký và không thể thay đổi.
			|Tiếp tục?';
			|ru = 'При записи документ будет зарегистрирован и станет недоступным для изменения.
			|Продолжить?';
			|en = 'After the document is saved, it is considered to be registered and is not available for editing.
			|Continue?'; fa = 'After the document is saved, it is considered to be registered and is not available for editing.
			|Continue?';
			|it = 'Durante la registrazione, il documento sarà registrato e non potrà più essere modificato.
			|Continuare?';
			|pl = 'Przy zapisywaniu dokument będzie zarejestrowany i stanie niedostępny do edycji.
			|Kontynuować?';
			|tr = 'Kayıt sırasında, belge kaydedilecek ve düzenlenemez hale gelecektir.
			|Devam et?'");
		IntegrationWith1CDocumentManagementClient.ShowQuestionYesNo(
			Notification,
			QueryText,
			IntegrationWith1CDocumentManagementCoreClient.QuestionParametersYesNo(DialogReturnCode.Yes));
		
	Else // The question is not needed.
		
		RunCallback(Notification, DialogReturnCode.Yes);
		
	EndIf;
	
EndProcedure

// Called before recording and closing after the user answers the question "Register?"
//
&AtClient
Procedure RecordAndPossiblyCloseCompletion(Response, NotificationParameters) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	If MultipleCounterparties = False Then
		UpdateTablePartCounterparties();
	EndIf;
	
	WriteObject();
	IntegrationWith1CDocumentManagementClient.Notify_DocumentEntry(ThisObject);
	If NotificationParameters.CloseAfterWrite Then
		Close();
	EndIf;
	If NotificationParameters.NotificationAfterRecording <> Undefined Then
		RunCallback(NotificationParameters.NotificationAfterRecording);
	EndIf;
	
EndProcedure

// Certainly closes the document with the transmission of its description.
//
&AtClient
Procedure CloseWithParameter()
	
	If ValueIsFilled(ID) Then
		Result = New Structure;
		Result.Insert("name", Presentation);
		Result.Insert("ID", ID);
		Result.Insert("type", Type);
		
		IntegrationWith1CDocumentManagementCoreClientServer.AddPersonalData(Result);
		IntegrationWith1CDocumentManagementCoreClientServer.FillInNDPOfPpeStructure(Result, ThisObject);
	Else
		Result = Undefined;
	EndIf;
	
	ClosingWithParameter = True;
	Close(Result);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Connection with the IP object

// It is called after the creation of the IC object and captures the created connection.
//
&AtClient
Procedure LinkCreateClickCompletion(Result, NotificationParameters) Export
	
	If Result <> Undefined Then
		IntegrationWith1CDocumentManagementClient.CreateIntegratedObjectBasedOnFormData(
			ThisObject, Result.Value);
	EndIf;
	
EndProcedure

// Called after selecting the type of IC object and starts selecting the object.
//
&AtClient
Procedure SelectLinkClickCompletion(Result, NotificationParameters) Export
	
	If Result <> Undefined Then
		ObjectTypeIS = IntegrationWith1CDocumentManagementServerCall.ObjectAttributeValue(
			Result.Value,
			"ObjectTypeIS");
		Notification = New CallbackDescription("SelectLinkPressEndSelection", ThisObject);
		OpenForm(ObjectTypeIS + ".ChoiceForm",, Items.SelectLink,,,, Notification);
	EndIf;
	
EndProcedure

// It is called after selecting the IC object and captures the created connection.
//
&AtClient
Procedure SelectLinkPressEndSelection(Result, NotificationParameters) Export
	
	If Result <> Undefined Then
		IntegrationWith1CDocumentManagementCoreServerCall.AddLink(
			ID,
			Type,
			Result,
			(Files.Count() > 0));
		IntegrationWith1CDocumentManagementCoreClient.Notify_AddingConnection(ID, Type, Result);
	EndIf;
	
EndProcedure

// Called after answering the question "Clear the connection?" and cleans it.
//
&AtClient
Procedure LinkClearClickCompletion(Response, NotificationParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		CacheExternalObject = ExternalObject;
		DeleteConnectionOnServer();
		IntegrationWith1CDocumentManagementCoreClient.Notify_RemovingLink(ID, Type, CacheExternalObject);
	EndIf;
	
EndProcedure

// Removes the link between the object BEFORE and the object IS.
//
&AtServer
Procedure DeleteConnectionOnServer()

	IntegrationWith1CDocumentManagementCoreServerCall.DeleteLink(ID, Type, ExternalObject);
	ExternalObject = Undefined;
	UpdateScenery();

EndProcedure

// Updates the form according to the status of the connection with the IP object.
//
&AtServer
Procedure UpdateScenery()
	
	DocumentFilledIn_ = ValueIsFilled(ExternalObject);
	
	Items.LinkObject.Visible = DocumentFilledIn_;
	Items.LinkClear.Visible = DocumentFilledIn_;
	Items.SelectLink.Visible = Not DocumentFilledIn_;
	Items.SVYAZGroup.Visible = (ID <> "");
	
	If DocumentFilledIn_ Then
		
		ObjectMetadata = ExternalObject.Metadata();
		If Common.IsDocument(ObjectMetadata) Then
			ExternalObjectPresentation = String(ExternalObject);
		Else
			ExternalObjectPresentation = StrTemplate("%1 (%2)", String(ExternalObject), ObjectMetadata.Presentation());
		EndIf;
		
	Else
		
		ObjectCreationIsPossible = (FillingRules.Count() > 0);
		
		If FillingRules.Count() = 1 Then
			TitleTextCreate = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'tạo mới %1';
					|ru = 'создать %1';
					|en = 'create %1'; fa = 'create %1';
					|it = 'creare %1';
					|pl = 'utwórz %1';
					|tr = '%1oluştur'"), Lower(FillingRules[0].Presentation));
		ElsIf FillingRules.Count() = 0 Then
			Items.SVYAZGroup.Visible = False;
			Return;
		Else
			TitleTextCreate = NStr("vi = 'tạo mới...';
									|ru = 'создать...';
									|en = 'create ...'; fa = 'create ...';
									|it = 'creare...';
									|pl = 'utwórz...';
									|tr = 'oluştur...'");
		EndIf;
		
		Items.LinkCreate.Title = TitleTextCreate;
		
	EndIf;
	
	Items.LinkCreate.Visible = Not DocumentFilledIn_ And ObjectCreationIsPossible;
	Items.CommunicationOr.Visible = Not DocumentFilledIn_ And ObjectCreationIsPossible;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Timekeeping and labor costs

// Completes timekeeping switching after answering the question "Turn off for other objects?".
//
&AtClient
Procedure SwitchTimingCompletion(Result, NotificationParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		Records = IntegrationWith1CDocumentManagementServerCall.
			SwitchTimeTrackingBy1CDocumentManagementObjects(NotificationParameters.ActiveEntries);
		
		For Each Record In Records Do
			NotificationParameters = New Structure;
			NotificationParameters.Insert("name", Record.Source);
			NotificationParameters.Insert("ID", Record.SourceID);
			NotificationParameters.Insert("type", Record.SourceType);
			Notify("Recording_1CDocumentManagementTimeSpent", NotificationParameters, Record.SourceID);
		EndDo;
	
		SwitchTimingServer();
		If TimekeepingEnabled Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Sử dụng đồng hồ tính thời gian theo ""%1""';
					|ru = 'Включен хронометраж по ""%1""';
					|en = 'Timing by ""%1"" is enabled'; fa = 'Timing by ""%1"" is enabled';
					|it = 'Crono-analisi attivata per ""%1""';
					|pl = 'Chronometraż jest włączony według ""%1""';
					|tr = '""%1"" ile kronometre etkin'"), String(Presentation));
			Status(Text);
		EndIf;
		
	EndIf;
	
EndProcedure

// Changes the form elements according to the current state of timekeeping.
//
&AtServer
Procedure SetPropertiesOfTimekeepingElementsServer()
	
	DataProcessors.IntegrationWith1CDocumentManagement.SetPropertiesOfTimekeepingElements(
		TimekeepingEnabled,
		Commands.SwitchTiming,
		Items.FormSwitchTiming);
	
EndProcedure

// Switches the timekeeping for the current object.
//
&AtServer
Procedure SwitchTimingServer()
	
	DataProcessors.IntegrationWith1CDocumentManagement.SwitchTiming(ThisObject);
	
EndProcedure

// Completes document registration after user confirmation.
//
&AtClient
Procedure RegisterCompletion(Response, NotificationParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		WriteObject();
		IntegrationWith1CDocumentManagementClient.Notify_DocumentEntry(ThisObject);
		RegisterOnServer();
		UpdateOverview();
	EndIf;
	
EndProcedure

// Registers the document and updates the details changed by this.
//
&AtServer
Procedure RegisterOnServer()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	XDTODataObject = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMInternalDocument");
	XDTODataObject.objectID = ThisObjectBefore(Proxy);
	XDTODataObject.name = Presentation;
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMDocumentRegistrationRequest");
	Query.document = XDTODataObject;
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
	IntegrationWith1CDocumentManagementCore.FillInFormDetailsFromXDTO(
		ThisObject,
		"RegistrationDate",
		Result.document,
		"regDate");
	IntegrationWith1CDocumentManagementCore.FillInFormDetailsFromXDTO(
		ThisObject,
		"RegistrationNumber",
		Result.document,
		"regNumber");
	IntegrationWith1CDocumentManagementCore.FillInFormDetailsFromXDTO(
		ThisObject,
		"State",
		Result.document,
		"status");
	
	DataProcessors.IntegrationWith1CDocumentManagement.SetDocumentStates(ThisObject, Result.document);
	Presentation = Result.document.name;
	
	// availability by status
	SetAvailabilityByState(Result.document);
	SetAvailabilityByItemInstance(Result.document);
	
	InitialRegistrationNumber = RegistrationNumber;
	InitialRegistrationDate = RegistrationDate;
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.SetRegistrationAvailability(
		ThisObject,
		Result.document);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Files

// Constructor of the parameter structure to start creating a file.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCoreClient.FileCreationStartParameters
//
&AtClient
Function FileCreationStartParameters()
	
	ParametersForStartOfCreation =
		IntegrationWith1CDocumentManagementCoreClient.FileCreationStartParameters();
	ParametersForStartOfCreation.IsScannedCopy =
		(StateAllowsAddingScannedCopy And Not StateAllowsFileAddition);
	ParametersForStartOfCreation.OwnerID = ID;
	ParametersForStartOfCreation.OwnerType = Type;
	ParametersForStartOfCreation.FormUniqueID = UUID;
	ParametersForStartOfCreation.OwnerPresentation = Presentation;
	ParametersForStartOfCreation.Owner = ExternalObject;
	ParametersForStartOfCreation.CallbackDescription =
		New CallbackDescription("ListOfFilesAfterAddingFile", ThisObject);
	
	Return ParametersForStartOfCreation;
	
EndFunction

// Completes file deletion after user confirmation.
//
&AtClient
Procedure FilesBeforeDeleteRowCompletion(Response, NotificationParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		MarkToDelete(NotificationParameters.SelectedRows);
		UpdateFileListClient();
	EndIf;
	
EndProcedure

&AtClient
Async Procedure FilesDragContinued(Val DragParameters)
	
	YouNeedToAddScannedCopy =
		Await IntegrationWith1CDocumentManagementCoreClient.YouNeedToAddScannedCopyAsync(
			StateAllowsAddingScannedCopy,
			StateAllowsFileAddition);
	
	If YouNeedToAddScannedCopy = DialogReturnCode.No Then
		Return;
	EndIf;
	
	If IsBlankString(ID) Then
		WriteObject();
		IntegrationWith1CDocumentManagementClient.Notify_DocumentEntry(ThisObject);
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.CreateFileFromDiskByDraggingAndDropping(
		DragParameters.Value,
		FileCreationStartParameters());
	
EndProcedure

// Completes copying files from the shared folder after user confirmation.
//
&AtClient
Procedure FillFilesByCopyingCompletion(Result, NotificationParameters) Export
	
	If Result = DialogReturnCode.No Then
		Return;
	EndIf;
	
	If IsBlankString(ID) Then
		WriteObject();
		IntegrationWith1CDocumentManagementClient.Notify_DocumentEntry(ThisObject);
	EndIf;
	
	Status(NStr("vi = 'Đang điền tệp bằng cách sao chép từ các tệp đính kèm...';
				|ru = 'Идет заполнение файлов копированием из присоединенных файлов...';
				|en = 'Filling in files by copying them from the attached files...'; fa = 'Filling in files by copying them from the attached files...';
				|it = 'Compilazione file tramite copiatura da file allegati...';
				|pl = 'Trwa wypełnienie plików kopiowaniem z załączonych plików...';
				|tr = 'Ekli dosyalardan kopyalanarak dosyalar dolduruluyor...'"));
	
	FillFilesByCopyingServer();
	
	Status();
	
EndProcedure

// Copies files from a shared folder and updates the list.
//
&AtServer
Procedure FillFilesByCopyingServer()
	
	IntegrationWith1CDocumentManagementCoreServerCall.FillFilesByCopying(
		ExternalObject, ID, Type, Presentation, UUID);
	ReadAndUpdateFileList();
	Items.FillFilesByCopying.Enabled = (Files.Count() = 0);
	
EndProcedure

// Retrieves the list of files from BEFORE and updates the form.
//
&AtServer
Procedure ReadAndUpdateFileList()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRetrieveRequest");
	FieldsReceived = Query.columnSet; // XDTOList
	ListOfObjects = Query.objectIDs; // XDTOList
	ListOfObjects.Add(ThisObjectBefore(Proxy));
	FieldsReceived.Add("files");
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);

	XDTODataObject = Result.objects[0];
	IntegrationWith1CDocumentManagementCoreServerCall.UpdateFileList(
		XDTODataObject.files, Files, Items.GroupFiles);
	
EndProcedure

// General completion of editing commands. Updates the list of files.
//
&AtClient
Procedure EditingCommandsCompletion(Result, Var_Parameters) Export
	
	UpdateFileListClient();
	
EndProcedure

// Completion of adding the printed form of the file. Updates the list.
//
// Parameters:
//   Result - Array of Structure - See IntegrationWith1CDocumentManagementCoreClientServer.NewFileCreationOptions
//   Var_Parameters - Undefined
//
&AtClient
Procedure InsertPrintFormCompletion(Result, Var_Parameters) Export
	
	If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
		UpdateFileListClient(Result[0].CurrentFile.ID);
	EndIf;
	
EndProcedure

// Opens the card of the current file.
//
&AtClient
Procedure OpenCard()
	
	If IsBlankString(ID) Then
		WriteObject();
		IntegrationWith1CDocumentManagementClient.Notify_DocumentEntry(ThisObject);
	EndIf;
	
	If Items.Files.CurrentData <> Undefined Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("EditingAllowed",
			StateAllowsFileEditing);
		IntegrationWith1CDocumentManagementCoreClient.OpenObject("DMFile", Items.Files.CurrentData.ID,
			ThisObject, AdditionalParameters);
		
	EndIf;
	
EndProcedure

// Marks the selected files for deletion.
//
&AtServer
Procedure MarkToDelete(Val SelectedRows)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	ListOfObjects = New Array;
	
	For Each LineNumber In SelectedRows Do
		Data = Files.FindByID(LineNumber);
		ListOfObjects.Add(New Structure("ID, Type", Data.ID, "DMFile"));
	EndDo;
	
	IntegrationWith1CDocumentManagementCore.MarkForDeletionUncheckItems(
		Proxy,
		ListOfObjects);
	
	ReadAndUpdateListOfSignatures();
	
EndProcedure

// Retrieves signatures from BEFORE and updates the list in the form.
//
&AtServer
Procedure FillSignatureList(XDTOSignatures, XDTOFiles)
	
	ObjectDocumentManagement =
		IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			ID,
			Type,
			Description);
	IntegrationWith1CDocumentManagementCore.FillSignatureList(
		ObjectDocumentManagement,
		XDTOSignatures,
		XDTOFiles,
		SignatureTree,
		NumberOfItemInstances,
		UUID);
	
EndProcedure

// Retrieves the list of files from BEFORE and updates it, saving the selected line.
//
&AtClient
Procedure UpdateFileListClient(FileID = Undefined)
	
	If FileID <> Undefined Then
		CurFileId = FileID;
	ElsIf Items.Files.CurrentData <> Undefined Then
		CurFileId = Items.Files.CurrentData.ID;
	EndIf;
	
	ReadAndUpdateFileList();
	
	// Let's restore the position in the list.
	For Each String In Files Do
		If String.ID = CurFileId Then
			Items.Files.CurrentRow = String.GetID();
			Break;
		EndIf;
	EndDo;
	
	Items.FillFilesByCopying.Enabled = (Files.Count() = 0);
	
EndProcedure

// Completion of adding a file. Updates the list.
//
// Parameters:
//   FilesDetails1 - Array of Structure - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//   Var_Parameters - Undefined
//
&AtClient
Procedure ListOfFilesAfterAddingFile(FilesDetails1, Var_Parameters) Export
	
	UpdateFileListClient(FilesDetails1[0].ID);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// DS

// Completes the signing of the document after answering the question "Sign?".
//
&AtClient
Procedure SignDocumentCompletion(Response, NotificationParameters) Export
	
	If Response <> DialogReturnCode.OK Then
		WriteObject();
		SetSignatures_();
	EndIf;
	
EndProcedure

// Signs the document.
//
&AtClient
Procedure SetSignatures_()
	
	DataArrayToStoreInDatabase = New Array;
	AddressesArray = New Array;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("DataArrayToStoreInDatabase", DataArrayToStoreInDatabase);
	NotificationParameters.Insert("AddressesArray", AddressesArray);
	
	Notification = New CallbackDescription("SetSignatures_Completion", ThisObject, NotificationParameters);
	
	ObjectBefore = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		ID,
		Type,
		Description,
		Title);
	
	IntegrationWith1CDocumentManagementCoreClient.StartCreatingItemSSignature(
		ObjectBefore,
		Files,
		AddressOfObjectSBinaryData,
		Notification);
	
EndProcedure

// Called after signing the document and updates the form.
//
&AtClient
Procedure SetSignatures_Completion(Result, NotificationParameters) Export
	
	OriginalSignatures = IntegrationWith1CDocumentManagementCoreClient.SignaturesArray(SignatureTree);
	AddSignaturesAndUpdateList(NotificationParameters.AddedObjectSignatures);
	Signatures = IntegrationWith1CDocumentManagementCoreClient.SignaturesArray(SignatureTree);
	
	If OriginalSignatures.Count() <> Signatures.Count() Then
		IntegrationWith1CDocumentManagementCoreClient.InformAboutSigning(
			Presentation,
			NotificationParameters.AddedObjectSignatures,
			ID,
			UUID);
	EndIf;
	
EndProcedure

// Depending on the availability of the signature, it changes the availability of the EP commands.
//
&AtClient
Procedure SetAvaliabilityOfDSCommandsList()
	
	HasSignatures = (SignatureTree.GetItems().Count() > 0);
	ThisIsSignature = IntegrationWith1CDocumentManagementCoreClient.ThisIsSignature(
		Items.SignatureTable.CurrentData);
	
	Items.SignatureTableOpenSignature.Enabled = HasSignatures;
	Items.SignatureTableContextMenuOpenSignature.Enabled = HasSignatures;
	
	Items.SignatureTableValidate.Enabled = HasSignatures;
	Items.SignatureTableContextMenuVerifySignature.Enabled = HasSignatures;
	
	Items.SignatureTableCheckEverything.Enabled = HasSignatures;
	Items.SignatureTableContextMenuCheckAllSignatures.Enabled = HasSignatures;
	
	Items.SignatureTableSave.Enabled = ThisIsSignature;
	Items.SignatureTableContextMenuSaveSignatureToDisk.Enabled = ThisIsSignature;
	
	Items.TableOfSignaturesDelete.Enabled = HasSignatures;
	Items.SignatureTableContextMenuDeleteSignature.Enabled = HasSignatures;
	
EndProcedure

// Adds the transferred signatures to the document.
//
&AtServer
Procedure AddSignaturesAndUpdateList(AddedObjectSignatures)
	
	IntegrationWith1CDocumentManagementCore.SignDocument(AddedObjectSignatures, SignatureTree);
	ReadAndUpdateListOfSignatures();
	
EndProcedure

// Gets signatures from BEFORE and updates the form.
//
&AtServer
Procedure ReadAndUpdateListOfSignatures()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRetrieveRequest");
	FieldsReceived = Query.columnSet; // XDTOList
	ListOfObjects = Query.objectIDs; // XDTOList
	ListOfObjects.Add(ThisObjectBefore(Proxy));
	
	FieldsReceived.Add("signatures");
	FieldsReceived.Add("files"); // we also update the files - so that the icon is signed to arrange
	FieldsReceived.Add("enabledProperties");
	FieldsReceived.Add("keyPropertiesValue");
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
	XDTODataObject = Result.objects[0];
	
	FillSignatureList(XDTODataObject.signatures, XDTODataObject.files);
	IntegrationWith1CDocumentManagementCoreServerCall.UpdateFileList(
		XDTODataObject.files, Files, Items.FilesDescription);
	
	SetAvailabilityByState(XDTODataObject);// availability by status
	SetAvailabilityByItemInstance(XDTODataObject);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Links

// Opens the currently linked document or its file.
//
&AtClient
Procedure OpenRelatedRowData(String)
	
	If String.Type = "DMRelationType" Then // the IP object.
		Return;
		
	ElsIf String.Type = "DMFile" Then // file.
		IntegrationWith1CDocumentManagementCoreClient.OpenFile(
			String.ID,
			String.Title,
			String.Extension,
			UUID);
		
	ElsIf ValueIsFilled(String.Ref) Then
		ShowValue(, String.Ref);
		
	Else
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(String.Type, String.ID, ThisObject);
		
	EndIf;
	
EndProcedure

// Called after adding a link and updates the link tree.
//
&AtClient
Procedure StartAddingLinkCompletion(Result, Var_Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	UpdateRelationshipTree(, Result.LinkedDocument.ID);
		
	If ValueIsFilled(AddressForLinkedDocumentFiles) Then
		AttachIdleHandler("UpdatingRelatedDocumentFiles", 1, True);
	EndIf;
		
EndProcedure

// Called after the link is deleted and updates the link tree.
//
&AtClient
Procedure StartDeletingLinkCompletion(Result, Var_Parameters) Export
	
	If ValueIsFilled(Result.SourceDocument_.ID) Then
		
		UpdateRelationshipTree();
		
		If ValueIsFilled(AddressForLinkedDocumentFiles) Then
			AttachIdleHandler("UpdatingRelatedDocumentFiles", 1, True);
		EndIf;
		
	Else
		
		LinkTypeString_ = Items.LinkTree.CurrentData.GetParent();
		RelationshipTypeStrings = LinkTypeString_.GetItems();
		DocumentLine = LinkTree.FindByID(Items.LinkTree.CurrentRow);
		RelationshipTypeStrings.Delete(DocumentLine);
		If RelationshipTypeStrings.Count() = 0 Then
			LinkTree.GetItems().Delete(LinkTypeString_);
		EndIf;
		
	EndIf;
	
	Modified = True;
	
EndProcedure

// Updates the document's link data, retrieving it anew if necessary.
//
// Parameters:
//   XDTODataObject - XDTODataObject - the document received from BEFORE, or
//              - Undefined - a sign of the need to get it.
//   AddedDocument - String - id of the document whose files need to be updated, or
//                       - Undefined - indicates whether all files need to be updated.
//
&AtServer
Procedure UpdateRelationshipTree(Val XDTODataObject = Undefined, AddedDocument = Undefined)
	
	If Not ValueIsFilled(ID) Then
		LinkTree.GetItems().Clear();
		Return;
	EndIf;
	
	If XDTODataObject = Undefined Then
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRetrieveRequest");
		FieldsReceived = Query.columnSet; // XDTOList
		ListOfObjects = Query.objectIDs; // XDTOList
		ListOfObjects.Add(ThisObjectBefore(Proxy));
		FieldsReceived.Add("relations");
		
		Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
		
		XDTODataObject = Result.objects[0];
	EndIf;
	
	AddressForLinkedDocumentFiles = DataProcessors.IntegrationWith1CDocumentManagement.
		FillInLinkTreeAndStartReceivingFiles(
			ThisObject,
			XDTODataObject,
			Items.LinkPage,
			AddedDocument);
	
EndProcedure

// Updates the files of related documents with temporary storage data filled
// in an asynchronous job, postponing the update if the data is not ready yet.
//
&AtClient
Procedure UpdatingRelatedDocumentFiles()
	
	If Not ValueIsFilled(AddressForLinkedDocumentFiles) Then
		Return;
	EndIf;
	
	// Let's save the current position by the object ID, taking into account the type of connection.
	CurrentData = Items.LinkTree.CurrentData;
	If CurrentData = Undefined Then
		Current_ID = Undefined;
		Current_Type = Undefined;
		CurTypeOfCommunication = Undefined;
	Else
		Current_ID = CurrentData.ID;
		Current_Type = CurrentData.Type;
		If Current_Type = "DMRelationType" Then
			LinkTypeString_ = CurrentData;
		ElsIf Current_Type = "DMFile" Then
			LinkTypeString_ = CurrentData.GetParent().GetParent();
		Else
			LinkTypeString_ = CurrentData.GetParent();
		EndIf;
		CurTypeOfCommunication = LinkTypeString_.ID;
	EndIf;
	
	If UpdatingRelatedDocumentFilesServer() Then // The data is not ready yet.
		
		AttachIdleHandler("UpdatingRelatedDocumentFiles", 1, True);
		
	Else // The data is received, expand the tree and restore the position in it.
		
		StringsLinkType = LinkTree.GetItems();
		For Each LinkTypeString In StringsLinkType Do
			
			Var_Id = LinkTypeString.GetID();
			Items.LinkTree.Expand(Var_Id, True);
			
			If Current_Type = Undefined Then
				Continue;
				
			ElsIf Current_Type = "DMRelationType" Then
				If LinkTypeString.ID = Current_ID Then
					Items.LinkTree.CurrentRow = Var_Id;
				EndIf;
				
			ElsIf LinkTypeString.ID = CurTypeOfCommunication Then
				
				LinesDocument = LinkTypeString.GetItems();
				For Each LineDocument In LinesDocument Do
					
					If Current_Type = "DMFile" Then
						LinesFile = LinesDocument.GetItems();
						For Each FileRow In LinesFile Do
							If FileRow.ID = Current_ID Then
								Items.LinkTree.CurrentRow = FileRow.GetID();
								Break;
							EndIf;
						EndDo;
						
					ElsIf LineDocument.ID = Current_ID Then
						Items.LinkTree.CurrentRow = LineDocument.GetID();
						Break;
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Updates the files of related documents with temporary storage data, if they are ready.
//
// Returns:
//   Boolean - True if re-updating is required, and False if not required.
//
&AtServer
Function UpdatingRelatedDocumentFilesServer()
	
	Result = GetFromTempStorage(AddressForLinkedDocumentFiles);
	If Result = Undefined Then
		Return True;
	EndIf;
	
	Tree = FormAttributeToValue("LinkTree");
	
	For Each LinkedDocument In Result Do
		
		TheStructureOfTheSearch = New Structure("ID, Type",
			LinkedDocument.ID,
			LinkedDocument.Type);
		DocumentStrings = Tree.Rows.FindRows(TheStructureOfTheSearch, True);
		For Each DocumentLine In DocumentStrings Do
			
			LinkedDocumentFiles = LinkedDocument.Files; // Array of Structure
			
			DocumentLine.Rows.Clear();
			For Each File In LinkedDocumentFiles Do
				FileString = DocumentLine.Rows.Add();
				FileString.ID = File.ID;
				FileString.Type = File.Type;
				FileString.Title = File.Description;
				FileString.Extension = File.Extension;
				FileString.Picture =
					IntegrationWith1CDocumentManagementCore.IndexOfFileIcon(FileString.Extension);
			EndDo;
			
		EndDo;
		
	EndDo;
	
	ValueToFormAttribute(Tree, "LinkTree");
	
	Return False;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////////////////////////
// Other

// Updates the HTML representation of the document.
//
&AtClient
Procedure UpdateOverview()
	
	If Items.GroupPages.CurrentPage = Items.OverviewPage Then
		PresentationHTML = IntegrationWith1CDocumentManagementClientServer.GetDocumentOverview(ThisObject);
	EndIf;
	
EndProcedure

// Fills in the form according to the data of the XDTO object, updating the overview and the relationship tree, but not the files.
//
&AtServer
Procedure ReadObjectIntoForm(XDTODataObject)
	
	// Filling in the details.
	MatchingBankDetails =
		Catalogs.RulesForIntegrationWith1CDocumentManagement.MatchingXDTPropertiesAndObjectFormDetailsTo(Type);
	IntegrationWith1CDocumentManagement.FillOutFormFromXDTOObject(ThisObject, XDTODataObject, MatchingBankDetails);
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.CustomizeDocumentFormAccordingToXDTODocumentView(
		ThisObject,
		XDTODataObject.documentType,
		XDTODataObject.organization);
	
	Presentation = XDTODataObject.name;
	
	InitialRegistrationNumber = RegistrationNumber;
	InitialRegistrationDate = RegistrationDate;
	
	// Availability by status.
	SetAvailabilityByState(XDTODataObject);
	SetAvailabilityByItemInstance(XDTODataObject);
	
	// The header is filled in according to the template.
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "titleBlockedByTemplate")
			And XDTODataObject.titleBlockedByTemplate = True Then
		Items.Description.ReadOnly = True;
		Items.Description.ToolTip =
			NStr("vi = 'Tên gọi chứng từ được tạo tự động theo khuôn mẫu và không thể chỉnh sửa.';
				|ru = 'Наименование документа сформировано автоматически по шаблону, редактирование запрещено.';
				|en = 'Document name is automatically generated according to the template, editing is not available.'; fa = 'Document name is automatically generated according to the template, editing is not available.';
				|it = 'La denominazione del documento è stata creata automaticamente da modello, è vietata la modifica.';
				|pl = 'Nazwa dokumentu została wygenerowana automatycznie według szablonu, edycja jest zabroniona.';
				|tr = 'Belgenin tanımı numuneye göre otomatik olarak oluşturulur, düzenlenmesi yasaktır.'");
		Items.Description.ToolTipRepresentation = ToolTipRepresentation.Button;
	EndIf;
	
	// Details of the nomenclature of cases
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "caseFilesCatalog") Then
		CaseFileNomenclatureYear = XDTODataObject.caseFilesCatalog.year;
	EndIf;
	
	// Counterparties
	If Counterparties.Count() = 1 Then
		SignedFromCounterparty = Counterparties[0].SignedFromCounterparty;
		SignedFromCounterpartyID = Counterparties[0].SignedFromCounterpartyID;
		SignedFromCounterpartyType = Counterparties[0].SignedFromCounterpartyType;
	EndIf;
	
	// Parties
	For Each String In Parties Do
		XDTORow = XDTODataObject.partyRows.rows[Parties.IndexOf(String)];
		legalPrivatePersonID = "";
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "party")
				And IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow.party, "correspondent") Then
			legalPrivatePersonID = XDTORow.party.correspondent.legalPrivatePerson.objectID.ID;
		EndIf;
		FillInAdditionalData(String, String.PartyType, legalPrivatePersonID);
	EndDo;
	
	Items.Organization.Visible = (XDTODataObject.organizationEnabled = True);
	Items.QuestionOfActivity.Visible = (XDTODataObject.activityMatterEnabled = True);
	Items.AccessBar.Visible = (XDTODataObject.accessLevelEnabled = True);
	Items.Files.Visible = (XDTODataObject.filesEnabled = True);
	Items.DocumentKind.Visible = (XDTODataObject.documentTypeEnabled = True);
	Items.State.Visible = (XDTODataObject.statusEnabled = True);
	Items.State.ReadOnly = (XDTODataObject.statusChangeEnabled <> True);
	Items.StateList.ReadOnly = (XDTODataObject.statusChangeEnabled <> True);
	RestrictAvailabilityOfFields = (XDTODataObject.limitPropertiesAvailability = True);
	
	// Projects and independent states.
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP") Then
		Items.Project.Visible = (XDTODataObject.projectsEnabled = True);
		Items.StateList.Visible = (XDTODataObject.statusEnabled = True);
		Items.State.Visible = False;
	Else
		Items.Project.Visible = False;
		Items.StateList.Visible = False;
		Items.State.Visible = (XDTODataObject.statusEnabled = True);
	EndIf;
	
	// Location
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1") Then
		
		Items.LocationGroup3.Visible = True;
		
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "contentAvailable")
				And XDTODataObject.contentAvailable Then
			Items.CompositionString.Visible = True;
			CompositionString = IntegrationWith1CDocumentManagementClientServer.GetDocumentCompositionString(ThisObject);
		Else
			Items.CompositionString.Visible = False;
		EndIf;
		
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "useCaseFiles")
				And XDTODataObject.useCaseFiles Then
			Items.ToDoItem.Visible = True;
		Else
			Items.CaseFileNomenclature.Visible = False;
			Items.ToDoItem.Visible = False;
		EndIf;
		
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "caseFilesCatalog") Then
			CaseFileNomenclature = XDTODataObject.caseFilesCatalog.objectID.presentation;
		EndIf;
		
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "caseFileDossier") Then
			ToDoItem = XDTODataObject.caseFileDossier.objectID.presentation;
		EndIf;
		
	Else
		Items.LocationGroup3.Visible = False;
	EndIf;
	
	ValidityPeriodPresentation =
		IntegrationWith1CDocumentManagementClientServer.PresentationOfValidityPeriodOfDocument(
			ValidityStartDate,
			Permanent,
			ValidityEndDate,
			ExtensionProcedureID,
			ExtensionProcedure);
			
	GeneratePresentationOfCFItems();
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.PlaceAdditionalDetailsOnForm(
		ThisObject,
		XDTODataObject);
	DataProcessors.IntegrationWith1CDocumentManagementCore.SetNavigationLink(
		ThisObject,
		XDTODataObject);
	DataProcessors.IntegrationWith1CDocumentManagement.FillInTimekeepingParameters(ThisObject, XDTODataObject);
	DataProcessors.IntegrationWith1CDocumentManagement.SetDocumentStates(ThisObject, XDTODataObject);
	DataProcessors.IntegrationWith1CDocumentManagement.SetDocumentTitle(ThisObject);
	
	If UseRelatedDocuments1CDocumentManagement Then
		UpdateRelationshipTree();
	EndIf;
	
	If ValueIsFilled(ID) Then
		FillingRules = IntegrationWith1CDocumentManagement.RulesForFillingIntegratedObjectsWithList(XDTODataObject);
	EndIf;
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.SetRegistrationAvailability(
		ThisObject,
		XDTODataObject);
	
EndProcedure

// Retrieves the updated state from BEFORE and refills the form.
//
&AtServer
Procedure RefreshStatus()
	
	// Get the object from BEFORE.
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRetrieveRequest");
	FieldsReceived = Query.columnSet; // XDTOList
	ListOfObjects = Query.objectIDs; // XDTOList
	ListOfObjects.Add(ThisObjectBefore(Proxy));
	
	FieldsReceived.Add("status");
	FieldsReceived.Add("statusApproval");
	FieldsReceived.Add("statusConfirmation");
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1.CORP") Then
		FieldsReceived.Add("statusSigning");
	EndIf;
	FieldsReceived.Add("statusRegistration");
	FieldsReceived.Add("statusConsideration");
	FieldsReceived.Add("statusPerformance");
	FieldsReceived.Add("statusEnabled");
	FieldsReceived.Add("enabledProperties");
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
	XDTODataObject = Result.objects[0];
	
	// Projects and independent states.
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP") Then
		Items.StateList.Visible = (XDTODataObject.statusEnabled = True);
		Items.State.Visible = False;
	Else
		Items.Project.Visible = False;
		Items.StateList.Visible = False;
		Items.State.Visible = (XDTODataObject.statusEnabled = True);
	EndIf;
	
	// Let's set availability by status.
	Items.State.ReadOnly = (XDTODataObject.statusChangeEnabled <> True);
	Items.StateList.ReadOnly = (XDTODataObject.statusChangeEnabled <> True);
	SetAvailabilityByState(XDTODataObject);
	
	// Fill in the details of the form corresponding to the condition.
	DataProcessors.IntegrationWith1CDocumentManagement.SetDocumentStates(ThisObject, XDTODataObject);
	
EndProcedure

// Fills out the document in TO and updates the form.
//
&AtServer
Procedure WriteObject(CheckConnections = True)
	
	Cancel = False;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	XDTODataObject = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMInternalDocument",
		ExternalObject);
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.GenerateAdditionalProperties(
		Proxy,
		XDTODataObject,
		ThisObject);
	
	// Requests for payment.
	If IsRequestForPayment Then
		FillInPaymentRequestDetails();
	EndIf;
	
	// Let's fill in simple properties according to the details of the form.
	MatchingBankDetails =
		Catalogs.RulesForIntegrationWith1CDocumentManagement.MatchingXDTPropertiesAndObjectFormDetailsTo(Type);
	For Each MapRow In MatchingBankDetails Do
		IntegrationWith1CDocumentManagement.FillInXDTPropertyOfOizPropsStructure(
			Proxy,
			XDTODataObject,
			MapRow.Key,
			ThisObject,
			MapRow.Value);
	EndDo;
	
	// Fill in the independent states.
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP") Then
		
		PossibleStates =
			Catalogs.RulesForIntegrationWith1CDocumentManagement.MatchingXDTPropertiesToDocumentStates(Type);
		For Each MapRow In PossibleStates Do
			IntegrationWith1CDocumentManagement.FillInXDTPropertyOfOizPropsStructure(
				Proxy,
				XDTODataObject,
				MapRow.Key,
				ThisObject,
				MapRow.Value);
		EndDo;
		
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreOverridable.BeforeWritingDocument(Proxy, XDTODataObject, ThisObject, Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	XDTODataObject.name = Presentation;
	If XDTODataObject.Properties().Get("checkRelations") <> Undefined Then
		XDTODataObject.checkRelations = CheckConnections;
	EndIf;
	
	If ValueIsFilled(ID) And ValueIsFilled(Type) Then // Update.
		
		XDTODataObject.objectID = ThisObjectBefore(Proxy);
		
		SignatureTable = IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable(
			SignatureTree,,
			ID);
		DataOfDocumentSignatures = IntegrationWith1CDocumentManagementCore.DataOfSignatures(SignatureTable);
		IntegrationWith1CDocumentManagementCore.FillInSignaturesOfXDTOObject(
			Proxy,
			XDTODataObject,
			DataOfDocumentSignatures);
		
		Result = IntegrationWith1CDocumentManagementCore.WriteObject(Proxy, XDTODataObject);
		
		XDTODataObject = Result.objects[0];
		
		If UseRelatedDocuments1CDocumentManagement
				And IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.0.1") Then
			DataProcessors.IntegrationWith1CDocumentManagement.RecordConnectionsOfNewDocument(
				LinkTree,
				ID,
				Type,
				Presentation);
		EndIf;
		
	Else // Creation.
		
		XDTODataObject.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy);
		
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMCreateRequest");
		Query.object = XDTODataObject;
		
		Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
		
		XDTODataObject = Result.object;
		ID = XDTODataObject.objectID.ID;
		Type = XDTODataObject.objectID.type;
		Presentation = Result.object.name;
		
		DataProcessors.IntegrationWith1CDocumentManagement.WriteNewDocumentFiles(
			Files,
			ID,
			Type,
			Presentation,
			ExternalObject);
		
		If UseRelatedDocuments1CDocumentManagement
				And IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.0.1") Then
			DataProcessors.IntegrationWith1CDocumentManagement.RecordConnectionsOfNewDocument(
				LinkTree,
				ID,
				Type,
				Presentation);
		EndIf;
		
		// Perhaps you need to assign a barcode to the created object.
		IntegrationWith1CDocumentManagementCore.SetBarcode(ExternalObject, ID, Type);
		
	EndIf;
	
	If TypeOf(ControlOverSendingFiles) = Type("ValueStorage") Then
		FileSendingControlTable = ControlOverSendingFiles.Get(); // See IntegrationWith1CDocumentManagementCore.ControlOverSendingFiles
		For Each String In FileSendingControlTable Do
			InformationRegisters.ControlOverSendingFilesTo1CDocumentManagement.SaveHashSumOfFileVersion(
				String.Source,
				String.FileName,
				String.SpreadsheetDocument)
		EndDo;
	EndIf;
	
	// We will write down the expense report of the application for the expense of Cash.
	If IsRequestForPayment
		And (RecipientType = "DMUser"
			Or IntegrationWith1CDocumentManagementCoreServerCall.TypeNameXDTO(RecipientType) = "DMUser") Then
		
		ConnectionIsAlreadyThere = False;
		XDTOAdvanceReport = IntegrationWith1CDocumentManagementCore.PredefinedValueBefore(
			"DMRelationType", "АвансовыйОтчет"); //@NON-NLS-2
		CommunicationTypeAdvanceReport = New Structure("ID, Type, Presentation",
			XDTOAdvanceReport.objectID.ID, XDTOAdvanceReport.objectID.type, XDTOAdvanceReport.name);
		SourceDocument_ = New Structure("ID, Type, Presentation", ID, Type, Presentation);
		
		For Each ElTypeOfCommunication In LinkTree.GetItems() Do
			If ElTypeOfCommunication.ID = CommunicationTypeAdvanceReport.ID Then
				
				For Each ELinkedDocument In ElTypeOfCommunication.GetItems() Do
					If ELinkedDocument.ID = ExpenseReportID
							And ELinkedDocument.Type = ExpenseReportType Then
						ConnectionIsAlreadyThere = True;
						
					Else
						LinkedDocument = New Structure("ID, Type, Presentation",
							ELinkedDocument.ID, ELinkedDocument.Type, ELinkedDocument.Title);
						IntegrationWith1CDocumentManagementServerCall.DeleteDocumentAssociation(
							SourceDocument_, LinkedDocument, CommunicationTypeAdvanceReport);
						
					EndIf;
				EndDo;
				
			EndIf;
		EndDo;
		
		If ConnectionIsAlreadyThere = False And ExpenseReportID <> "" Then
			LinkedDocument = New Structure("ID, Type, Presentation",
				ExpenseReportID, ExpenseReportType, ExpenseReport);
			IntegrationWith1CDocumentManagementServerCall.AddDocumentLink(
				SourceDocument_, LinkedDocument, CommunicationTypeAdvanceReport);
		EndIf;
		
	EndIf;
	
	ReadObjectIntoForm(XDTODataObject);
	
	If XDTODataObject.IsSet("keyPropertiesValue") Then
		AddressOfObjectSBinaryData.AddressOfDocumentImpression = PutToTempStorage(
			XDTODataObject.keyPropertiesValue, UUID);
	EndIf;
	
	Modified = False;
	
EndProcedure

&AtServer
Procedure FillInPaymentRequestDetails()
	
	Counterparty = "";
	CounterpartyID = "";
	CounterpartyType = "";
	Counterparties.Clear();
	If (RecipientType = "DMCorrespondent"
		Or RecipientType = IntegrationWith1CDocumentManagementCoreServerCall.TypeNameIS("DMCorrespondent"))
			And ValueIsFilled(RecipientID) Then
		CounterpartyLine = Counterparties.Add();
		CounterpartyLine.Counterparty = Recipient;
		CounterpartyLine.CounterpartyID = RecipientID;
		CounterpartyLine.CounterpartyType = RecipientType;
		Counterparty = Recipient;
		CounterpartyID = RecipientID;
		CounterpartyType = RecipientType;
	EndIf;
	
	Parties.Clear();
	If ValueIsFilled(OrganizationID) Then
		PayerParty = Parties.Add();
		PayerParty.Party = Organization;
		PayerParty.PartyID = OrganizationID;
		PayerParty.PartyType = OrganizationType;
		NamePayerXDTO = IntegrationWith1CDocumentManagementCore.PredefinedValueBefore(
			"DMPartyName", "Плательщик"); //@NON-NLS-2
		PayerParty.Description = NamePayerXDTO.name;
		PayerParty.DescriptionID = NamePayerXDTO.objectID.ID;
		PayerParty.DescriptionType = NamePayerXDTO.objectID.type;
	EndIf;
	If ValueIsFilled(RecipientID) Then
		RecipientParty = Parties.Add();
		RecipientParty.Party = Recipient;
		RecipientParty.PartyID = RecipientID;
		RecipientParty.PartyType = RecipientType;
		NameRecipientXDTO = IntegrationWith1CDocumentManagementCore.PredefinedValueBefore(
			"DMPartyName", "Получатель"); //@NON-NLS-2
		RecipientParty.Description = NameRecipientXDTO.name;
		RecipientParty.DescriptionID = NameRecipientXDTO.objectID.ID;
		RecipientParty.DescriptionType = NameRecipientXDTO.objectID.type;
	EndIf;
	
EndProcedure

// Processing the form when changing the document type.
//
&AtServer
Procedure WhenChangingDocumentView()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Objects = New Array;
	Objects.Add(New Structure("ID, Type", DocumentKindID, DocumentKindType));
	If OrganizationID <> "" And OrganizationType = "DMOrganization" Then
		Objects.Add(New Structure("ID, Type", OrganizationID, OrganizationType));
	EndIf;
	ObjectsDataBefore = IntegrationWith1CDocumentManagementCore.GetObjects(Proxy, Objects);
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.WhenChangingViewOnDocumentForm(
		ThisObject,
		ObjectsDataBefore);
	UpdateScenery();
	
	MultipleCounterparties = (Counterparties.Count() > 1);
	SetCounterpartyVisibility();
	
EndProcedure

// Sets the availability of fields and buttons of the form depending on the state of the document.
//
&AtServer
Procedure SetAvailabilityByState(XDTODataObject)
	
	IntegrationWith1CDocumentManagementCoreClientServer.SetValuesOfAllNDPSFields(
		ThisObject,
		True);
	IntegrationWith1CDocumentManagementCore.FillInPPEOfXDTOObject(ThisObject, XDTODataObject);
	
	AvailableFields = New Array;
	For Each FieldName In XDTODataObject.enabledProperties Do
		AvailableFields.Add(Lower(FieldName));
	EndDo;
	
	NumberOfAvailableFields = AvailableFields.Count();
	
	MatchingBankDetails =
		Catalogs.RulesForIntegrationWith1CDocumentManagement.MatchingXDTPropertiesAndObjectFormDetailsTo(Type);
	AddMatchingDetails(MatchingBankDetails);
	For Each MapRow In MatchingBankDetails Do
		
		If TypeOf(MapRow.Value) = Type("Structure") Then
			If MapRow.Value.Property("rows") Then
				AttributeName = MapRow.Value.rows[0];
			Else
				Continue;
			EndIf;
		Else
			AttributeName = MapRow.Value;
		EndIf;
		
		If AttributeName = "ValidityStartDate"
				Or AttributeName = "ValidityEndDate"
				Or AttributeName = "ExtensionProcedure"
				Or AttributeName = "Permanent" Then
			AttributeName = "ValidityPeriodPresentation";
		EndIf;
		
		// We will skip the details that are not displayed on the form.
		If Items.Find(AttributeName) = Undefined Then
			Continue;
		EndIf;
		
		If NumberOfAvailableFields = 0 Or AvailableFields.Find(Lower(MapRow.Key)) <> Undefined Then
			Items[AttributeName].ReadOnly = False;
		Else
			Items[AttributeName].ReadOnly = True;
		EndIf;
		
	EndDo;
	
	If (NumberOfAvailableFields = 0 Or AvailableFields.Find("register") <> Undefined)
			And AutomaticNumbering Then
		Items.Register.Enabled = True;
	Else
		Items.Register.Enabled = False;
	EndIf;
	
	If NumberOfAvailableFields = 0 Or AvailableFields.Find("additionalproperties") <> Undefined Then
		Items.Properties.Enabled = True;
	Else
		Items.Properties.Enabled = False;
	EndIf;
	
	Items.Files.ChangeRowSet = (StateAllowsFileAddition Or StateAllowsAddingScannedCopy);
	Items.AddPrintedForm.Enabled = ValueIsFilled(ExternalObject)
		And StateAllowsFileAddition;
	
	Items.CreateFile.Enabled = (StateAllowsFileAddition Or StateAllowsAddingScannedCopy);
	Items.FilesContextCreateFile.Enabled = (StateAllowsFileAddition
		Or StateAllowsAddingScannedCopy);
	
EndProcedure

// Sets the availability of file commands according to the status of the current file.
//
&AtClient
Procedure SetAvailabilityOfFileListCommands()
	
	CurrentData = Items.Files.CurrentData;
	If CurrentData = Undefined Then
		
		Items.OpenForReading.Enabled = False;
		Items.ContextFilesOpenForReading.Enabled = False;
		
		Items.OpenForEditing.Enabled = False;
		Items.ContextFilesOpenForEditing.Enabled = False;
		
		Items.EndEdit.Enabled = False;
		Items.FilesContextFinishEditing.Enabled = False;
		
		Items.SaveToDisk.Enabled = False;
		Items.UpdateFromFileOnHardDrive.Enabled = False;
		Items.SaveChanges.Enabled = False;
		Items.CancelEdit.Enabled = False;
		
		Items.OpenCard.Enabled = False;
		Items.FilesContextOpenCard.Enabled = False;
		
		Items.DeleteFile.Enabled = False;
		Items.FilesContextDeleteFile.Enabled = False;
		
		Items.FillFileWithDocumentData.Enabled = False;
		
		Items.Sign.Enabled = False;
		Items.AddDSFromFile.Enabled = False;
		Items.SaveWithDigitalSignature.Enabled = False;
		
	Else
		
		IsBeingEdited = CurrentData.IsBeingEdited;
		EditedByCurUser = CurrentData.EditedByCurUser;
		EditedByAnotherUser = IsBeingEdited And Not EditedByCurUser;
		
		Items.OpenForReading.Enabled = True;
		Items.ContextFilesOpenForReading.Enabled = True;
		
		Items.OpenForEditing.Enabled = StateAllowsFileEditing
			And FileCaptureIsAvailable And Not EditedByAnotherUser;
		Items.ContextFilesOpenForEditing.Enabled = StateAllowsFileEditing
			And FileCaptureIsAvailable And Not EditedByAnotherUser;
			
		Items.EndEdit.Enabled = StateAllowsFileEditing
			And FileCaptureIsAvailable And EditedByCurUser;
		Items.FilesContextFinishEditing.Enabled = StateAllowsFileEditing
			And FileCaptureIsAvailable And EditedByCurUser;
			
		Items.SaveChanges.Enabled = StateAllowsFileEditing
			And FileCaptureIsAvailable And EditedByCurUser;
		Items.CancelEdit.Enabled = StateAllowsFileEditing
			And FileCaptureIsAvailable And EditedByCurUser;
		Items.SaveToDisk.Enabled = True;
		Items.UpdateFromFileOnHardDrive.Enabled = StateAllowsFileEditing
			And Not EditedByAnotherUser;
			
		Items.OpenCard.Enabled = True;
		Items.FilesContextOpenCard.Enabled = True;
		
		Items.DeleteFile.Enabled = StateAllowsFileEditing
			And Not EditedByAnotherUser;
		Items.FilesContextDeleteFile.Enabled = StateAllowsFileEditing
			And Not EditedByAnotherUser;
			
		Items.FillFileWithDocumentData.Enabled = Not IsBeingEdited;
			
		SignedWithDS = CurrentData.SignedWithDS;
		Encrypted = CurrentData.Encrypted;
		
		Items.Sign.Enabled = Not IsBeingEdited And Not Encrypted;
		Items.AddDSFromFile.Enabled = Not IsBeingEdited And Not Encrypted;
		Items.SaveWithDigitalSignature.Enabled = SignedWithDS;
		
	EndIf;
	
EndProcedure

// sets the availability of the document Attributes, depending on the presence of the signature.
//
&AtServer
Procedure SetAvailabilityByItemInstance(XDTODataObject)
	
	If XDTODataObject.signatures.Count() <> 0 Then
		KeyFields = New Array;
		KeyFields.Add("Description");
		KeyFields.Add("LongDesc");
		For Each FieldName In KeyFields Do
			Items[FieldName].ReadOnly = True;
		EndDo;
	EndIf;
	
EndProcedure

// Continues to create a business process after answering the question "Write a document?".
//
&AtClient
Procedure CreateBusinessProcessCompletion(Result, NotificationParameters) Export
	
	IntegrationWith1CDocumentManagementClient.CreateABusinessProcessByTheObjectDM(ID, Type, Description, ExternalObject);
	
EndProcedure

// Calls the handler of the command that was added programmatically when creating the form on the server.
// (See IntegrationWith1CDocumentManagementCoreOverridable.AdditionalProcessingOfDocumentForm).
//
&AtClient
Procedure Attachable_ExecuteProgrammaticallyAddedCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClientOverridable.ExecuteProgrammaticallyAddedCommand(
		Command, ThisObject);
	
EndProcedure

// Forms a representation of the DDS articles according to the list.
//
&AtServer
Procedure GeneratePresentationOfCFItems()
	
	If Not KeepRecordsOfCFItem Then
		Return;
	EndIf;
	
	NumberOfArticles = CFItems.Count();
	Items.PresentationOfCFItems.MarkIncomplete = (NumberOfArticles = 0);
	
	If NumberOfArticles <= 1 Then
		
		Items.CFItemsPages.CurrentPage = Items.PageArticleDDS;
		Items.PresentationOfCFItems.TextEdit = True;
		
		If NumberOfArticles = 1 Then
			PresentationOfCFItems = CFItems[0].CFItem;
		Else
			PresentationOfCFItems = "";
		EndIf;
		
	Else // A few articles.
		
		Items.CFItemsPages.CurrentPage = Items.CFItemsPage;
		Items.PresentationOfCFItems.TextEdit = False;
		
		// Let's assemble the presentation of articles in a row in the form field.
		Result = "";
		For Each String In CFItems Do
			If Result <> "" Then
				Result = Result + "; ";
			EndIf;
			Result = Result + String.CFItem;
		EndDo;
		
		PresentationOfCFItems = Result;
		
	EndIf;
	
EndProcedure

// Opens the form for viewing and editing the transcript of the DDS articles.
//
&AtClient
Procedure OpenCFItems()
	
	FormParameters = New Structure;
	
	FormParameters.Insert("CFItems", New Array);
	For Each String In CFItems Do
		StringStructure = New Structure;
		StringStructure.Insert("CFItem", String.CFItem);
		StringStructure.Insert("CFItemID", String.CFItemID);
		StringStructure.Insert("CFItemType", String.CFItemType);
		StringStructure.Insert("Sum", String.Sum);
		StringStructure.Insert("VATAmount", String.VATAmount);
		FormParameters.CFItems.Add(StringStructure);
	EndDo;
	
	FormParameters.Insert("Sum", Sum);
	FormParameters.Insert("VATAmount", VATAmount);
	FormParameters.Insert("ConsiderVAT", ConsiderVAT);
	FormParameters.Insert("ReadOnly",
		Items.PresentationOfCFItems.ReadOnly Or ReadOnly);
		
	CallbackDescription = New CallbackDescription("OpenCFItemsCompletion", ThisObject);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.CashFlowReportItems",
		FormParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

// Completes the editing of the transcript for the articles of the DDS.
//
&AtClient
Procedure OpenCFItemsCompletion(Result, Var_Parameters) Export
	
	If TypeOf(Result) <> Type("Array") Then
		Return;
	EndIf;
	
	Modified = True;
	CFItems.Clear();
	Sum = 0;
	VATAmount = 0;
	For Each StringStructure In Result Do
		String = CFItems.Add();
		String.CFItem = StringStructure.CFItem;
		String.CFItemID = StringStructure.CFItemID;
		String.CFItemType = StringStructure.CFItemType;
		String.Sum = StringStructure.Sum;
		String.VATAmount = StringStructure.VATAmount;
		Sum = Sum + StringStructure.Sum;
		VATAmount = VATAmount + StringStructure.VATAmount;
	EndDo;
	GeneratePresentationOfCFItems();
	
	Items.IfAmountIsCorrectIncorrect.CurrentPage = Items.SumPageIsCorrect;
	
EndProcedure

// Updates the display of the amount, checking it with the decryption.
//
&AtClient
Procedure UpdateAmountDisplay()
	
	If Not KeepRecordsOfCFItem Then
		Return;
	EndIf;
	
	NumberOfArticles = CFItems.Count();
	If NumberOfArticles = 1 Then
		CFItems[0].Sum = Sum;
	ElsIf NumberOfArticles > 1 Then
		TotalAmount_5 = 0;
		For Each String In CFItems Do
			TotalAmount_5 = TotalAmount_5 + String.Sum;
		EndDo;
		If TotalAmount_5 = Sum Then
			Items.IfAmountIsCorrectIncorrect.CurrentPage =
				Items.SumPageIsCorrect;
		Else
			Items.IfAmountIsCorrectIncorrect.CurrentPage =
				Items.AmountPageIsIncorrect;
		EndIf;
	EndIf;
	
EndProcedure

// Updates the display of the VAT amount, checking it with the transcript.
//
&AtClient
Procedure UpdateDisplayOfVATAmount()
	
	If Not KeepRecordsOfCFItem Or Not ConsiderVAT Then
		Return;
	EndIf;
	
	NumberOfArticles = CFItems.Count();
	If NumberOfArticles = 1 Then
		CFItems[0].VATAmount = VATAmount;
	ElsIf NumberOfArticles > 1 Then
		TotalAmount_5 = 0;
		For Each String In CFItems Do
			TotalAmount_5 = TotalAmount_5 + String.VATAmount;
		EndDo;
		If TotalAmount_5 = VATAmount Then
			Items.IfAmountIsCorrectIncorrect.CurrentPage =
				Items.SumPageIsCorrect;
		Else
			Items.IfAmountIsCorrectIncorrect.CurrentPage =
				Items.AmountPageIsIncorrect;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectItems(ProductData_1, StandardProcessing, Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Products", ProductData_1, StandardProcessing, ThisObject, True, Item);
	
	FillInAdditionalProductData(ProductData_1, CurrentData);
	
EndProcedure

&AtClient
Procedure FillInAdditionalProductData(ProductData_1, CurrentData)
	
	If CurrentData.Count = 0 Then
		CurrentData.Count = 1;
	EndIf;
	
	CurrentData.Price = ProductData_1.price;
	
	If ProductData_1.measurementUnit <> Undefined Then
		CurrentData.UnitOfMeasure = ProductData_1.measurementUnit;
		CurrentData.UnitOfMeasureID = ProductData_1.measurementUnitID;
		CurrentData.UnitOfMeasureType = ProductData_1.measurementUnitType;
	Else
		CurrentData.UnitOfMeasure = "";
		CurrentData.UnitOfMeasureID = "";
		CurrentData.UnitOfMeasureType = "";
	EndIf;
	
	If ProductData_1.VATRate <> Undefined Then
		CurrentData.VATRate = ProductData_1.VATRate;
		CurrentData.VATRateID = ProductData_1.VATRateID;
		CurrentData.VATRateType = ProductData_1.VATRateType;
	Else
		CurrentData.VATRate = "";
		CurrentData.VATRateID = "";
		CurrentData.VATRateType = "";
	EndIf;
	
	WhenChangingProductsQuantity(CurrentData);
	
EndProcedure

&AtServer
Function ProductData_1(ProductsType, ProductsID)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ProductData_1 = New Structure(
		"price, measurementUnit, measurementUnitID, measurementUnitType, VATRate, VATRateID, VATRateType");
	
	XDTOProducts = IntegrationWith1CDocumentManagementCore.GetObject(
		Proxy,
		ProductsType,
		ProductsID);
	ProductData_1.price = XDTOProducts.price;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOProducts, "measurementUnit")
			And IntegrationWith1CDocumentManagementCore.PropertySet(XDTOProducts.measurementUnit, "objectID") Then
		ProductData_1.measurementUnit = XDTOProducts.measurementUnit.name;
		ProductData_1.measurementUnitID = XDTOProducts.measurementUnit.objectID.ID;
		ProductData_1.measurementUnitType = XDTOProducts.measurementUnit.objectID.type;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOProducts, "VATRate")
			And IntegrationWith1CDocumentManagementCore.PropertySet(XDTOProducts.VATRate, "objectID") Then
		ProductData_1.VATRate = XDTOProducts.VATRate.name;
		ProductData_1.VATRateID = XDTOProducts.VATRate.objectID.ID;
		ProductData_1.VATRateType = XDTOProducts.VATRate.objectID.type;
	EndIf;
	
	Return ProductData_1;
	
EndFunction

&AtClient
Procedure WhenChangingProductsQuantity(RowData)
	
	RowData.Sum = RowData.Price * RowData.Count;
	WhenChangingGoodsAmount(RowData);
	
EndProcedure

&AtClient
Procedure WhenChangingProductsPrice(RowData)
	
	RowData.Sum = RowData.Price * RowData.Count;
	WhenChangingGoodsAmount(RowData);
	
EndProcedure

&AtClient
Procedure WhenChangingGoodsVATRate(RowData)
	
	BidByNumber = VATRateByNumber(RowData.VATRateID);
	RowData.VATAmount = RowData.Sum * BidByNumber / (1 + BidByNumber);
	
	WhenChangingGoodsAmountOfVAT(RowData);
	
EndProcedure

&AtClient
Procedure WhenChangingGoodsAmountOfVAT(RowData)
	
	VATAmount = Goods.Total("VATAmount");
	
	UpdateDisplayOfVATAmount();
	
EndProcedure

&AtClient
Procedure WhenChangingGoodsAmount(RowData)
	
	BidByNumber = VATRateByNumber(RowData.VATRateID);
	RowData.VATAmount = RowData.Sum * BidByNumber / (1 + BidByNumber);
	Sum = Goods.Total("Sum");
	
	UpdateAmountDisplay();
	
	WhenChangingGoodsAmountOfVAT(RowData);
	
EndProcedure

&AtClient
Function VATRateByNumber(VATRate)
	
	If VATRate = "VAT22" Then
		Return 0.22;
	ElsIf VATRate = "VAT20" Then
		Return 0.2;
	ElsIf VATRate = "VAT18" Then
		Return 0.18;
	ElsIf VATRate = "VAT10" Then
		Return 0.10;
	ElsIf VATRate = "VAT7" Then
		Return 0.07;
	ElsIf VATRate = "VAT5" Then
		Return 0.05;
	Else
		Return 0;
	EndIf;
	
EndFunction

&AtClient
Procedure AutoSideSelection(StandardProcessing, ChoiceData, Text)
	
	OrganizationSelectionData = New ValueList();
	IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
		"DMOrganization", OrganizationSelectionData, Text, StandardProcessing);
	CounterpartySelectionData = New ValueList();
	IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
		"DMCorrespondent", CounterpartySelectionData, Text, StandardProcessing);
	
	ChoiceData = New ValueList();
	For Each Item In OrganizationSelectionData Do
		Item.Presentation = StrTemplate(NStr("vi = '%1 (Doanh nghiệp)';
											|ru = '%1 (Организация)';
											|en = '%1 (Company)'; fa = '%1 (Company)';
											|it = '%1 (Azienda)';
											|pl = '%1 (Firma)';
											|tr = '%1 (İş yeri)'"), Item.Presentation);
		ChoiceData.Add(Item);
	EndDo;
	For Each Item In CounterpartySelectionData Do
		Item.Presentation = StrTemplate(NStr("vi = '%1 (Đối tác)';
											|ru = '%1 (Контрагент)';
											|en = '%1 (Counterparty)'; fa = '%1 (Counterparty)';
											|it = '%1 (Controparte)';
											|pl = '%1 (Kontrahent)';
											|tr = '%1 (Cari hesap)'"), Item.Presentation);
		ChoiceData.Add(Item);
	EndDo;
	
EndProcedure

&AtClient
Procedure AutomaticRecipientSelection(StandardProcessing, ChoiceData, Text)
	
	UserSelectionData = New ValueList();
	IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
		"DMUser", UserSelectionData, Text, StandardProcessing);
	CounterpartySelectionData = New ValueList();
	IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
		"DMCorrespondent", CounterpartySelectionData, Text, StandardProcessing);
	
	ChoiceData = New ValueList();
	For Each Item In UserSelectionData Do
		Item.Presentation = StrTemplate(NStr("vi = '%1 (Người sử dụng)';
											|ru = '%1 (Пользователь)';
											|en = '%1 (User)'; fa = '%1 (User)';
											|it = '%1 (Utente)';
											|pl = '%1 (Użytkownik)';
											|tr = '%1 (Kullanıcı)'"), Item.Presentation);
		ChoiceData.Add(Item);
	EndDo;
	For Each Item In CounterpartySelectionData Do
		Item.Presentation = StrTemplate(NStr("vi = '%1 (Đối tác)';
											|ru = '%1 (Контрагент)';
											|en = '%1 (Counterparty)'; fa = '%1 (Counterparty)';
											|it = '%1 (Controparte)';
											|pl = '%1 (Kontrahent)';
											|tr = '%1 (Cari hesap)'"), Item.Presentation);
		ChoiceData.Add(Item);
	EndDo;
	
EndProcedure

&AtClient
Procedure CleanTSSideContacts()
	
	CurrentData = Items.Parties.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData.ContactPerson = "";
	CurrentData.ContactPersonID = "";
	CurrentData.ContactPersonType = "";
	
	CurrentData.SignedBy = "";
	CurrentData.SignedByID = "";
	CurrentData.SignedByType = "";
	
EndProcedure

&AtClient
Procedure ClearContactsTSCounterparties()
	
	CurrentData = Items.Counterparties.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData.ContactPerson = "";
	CurrentData.ContactPersonID = "";
	CurrentData.ContactPersonType = "";
	
	CurrentData.SignedFromCounterparty = "";
	CurrentData.SignedFromCounterpartyID = "";
	CurrentData.SignedFromCounterpartyType = "";
	
EndProcedure

&AtClient
Procedure ClearDocumentContacts()
	
	ContactPerson = "";
	ContactPersonID = "";
	ContactPersonType = "";
	
	SignedFromCounterparty = "";
	SignedFromCounterpartyID = "";
	SignedFromCounterpartyType = "";
	
EndProcedure

&AtClient
Procedure AutoSelectionContactPerson(StandardProcessing, ChoiceData, Text)
	
	If ValueIsFilled(CounterpartyID) Then
		
		Correspondent = New Structure;
		Correspondent.Insert("ID", CounterpartyID);
		Correspondent.Insert("type", "DMCorrespondent");
		
		Filter = New Structure;
		Filter.Insert("correspondent", Correspondent);
		
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMContactPerson", ChoiceData, Text, StandardProcessing, Filter);
		
	Else
		ChoiceData = New ValueList();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AutoSelectionTSPartyContactPerson(StandardProcessing, ChoiceData, Text)
	
	CurrentData = Items.Parties.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.PartyType = "DMOrganization" Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMUser", ChoiceData, Text, StandardProcessing);
		
	ElsIf CurrentData.PartyType = "DMCorrespondent" Then
		Correspondent = New Structure;
		Correspondent.Insert("ID", CurrentData.PartyID);
		Correspondent.Insert("type", "DMCorrespondent");
		
		Filter = New Structure;
		Filter.Insert("correspondent", Correspondent);
		
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMContactPerson", ChoiceData, Text, StandardProcessing, Filter);
		
	Else
		ChoiceData = New ValueList();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AutoSelectionContactPersonTSContractors(StandardProcessing, ChoiceData, Text)
	
	CurrentData = Items.Counterparties.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.Counterparty) Then
		Correspondent = New Structure;
		Correspondent.Insert("ID", CurrentData.CounterpartyID);
		Correspondent.Insert("type", "DMCorrespondent");
		
		Filter = New Structure;
		Filter.Insert("correspondent", Correspondent);
		
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMContactPerson", ChoiceData, Text, StandardProcessing, Filter);
		
	Else
		ChoiceData = New ValueList();
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInAdditionalData(String, PartyType, legalPrivatePersonID)
	
	If Left(PartyType, 2) = "DM" Then
		SideTypeXDTO = PartyType;
	Else
		SideTypeXDTO = IntegrationWith1CDocumentManagementCoreServerCall.TypeNameXDTO(PartyType);
	EndIf;
	
	If SideTypeXDTO = "DMCorrespondent" Then
		String.SidePictureIndex = 1;
		
		If legalPrivatePersonID = "ФизЛицо" Then //@NON-NLS-1
			String.CounterpartyIsIndividual = True;
		Else
			String.CounterpartyIsIndividual = False;
		EndIf;
		
	ElsIf SideTypeXDTO = "DMOrganization" Then
		String.SidePictureIndex = 2;
		String.CounterpartyIsIndividual = False;
		
	Else
		String.SidePictureIndex = 0;
		String.CounterpartyIsIndividual = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TransferCounterpartyAndOrganizationFromPartySTsToDetails()
	
	NumberOfParties = Parties.Count();
	
	CounterpartyTypeName = IntegrationWith1CDocumentManagementCoreServerCall.TypeNameIS("DMCorrespondent");
	
	// copying a counterparty
	IndexOfParties = NumberOfParties - 1;
	While IndexOfParties > -1 Do
		String = Parties[IndexOfParties];
		If ValueIsFilled(String.Party)
				And (String.PartyType = "DMCorrespondent" Or String.PartyType = CounterpartyTypeName) Then
			Counterparty = String.Party;
			CounterpartyID = String.PartyID;
			CounterpartyType = String.PartyType;
		EndIf;
		
		IndexOfParties = IndexOfParties - 1;
	EndDo;
	
	// copying an organization
	If NumberOfParties > 0
			And (Parties[0].PartyType = "DMOrganization"
				Or IntegrationWith1CDocumentManagementCoreServerCall.TypeNameXDTO(
					Parties[0].PartyType) = "DMOrganization") Then
		If OrganizationID <> Parties[0].PartyID Then
			Organization = String.Party;
			OrganizationID = String.PartyID;
			OrganizationType = String.PartyType;
			If Parties[0].PartyType = "DMOrganization" Then
				ThisOrganization = ThisOrganization(OrganizationType, OrganizationID);
				UpdateVATVisibility(ThisOrganization);
			EndIf;
		EndIf;
	EndIf;

EndProcedure

&AtServer
Procedure AddMatchingDetails(MatchingBankDetails)
	
	MatchingBankDetails.Insert("cashFlowRows", "PresentationOfCFItems");
	MatchingBankDetails.Insert("correspondent", "CounterpartyGroup");
	MatchingBankDetails.Insert("correspondentRows", "CounterpartiesPage");
	
EndProcedure

&AtClient
Procedure UpdatePageTitleCounterparties()
	
	CounterpartiesCount = Counterparties.Count();
	
	If CounterpartiesCount = 0 Then
		Items.CounterpartiesPage.Title = NStr("vi = 'Đối tác';
												|ru = 'Контрагенты';
												|en = 'Counterparties'; fa = 'طرف‌حساب‌ها';
												|it = 'Controparti';
												|pl = 'Counterparties';
												|tr = 'Cari hesaplar'");
	Else
		Items.CounterpartiesPage.Title = StrTemplate(
			NStr("vi = 'Đối tác ( %1)';
				|ru = 'Контрагенты (%1)';
				|en = 'Counterparties (%1)'; fa = 'Counterparties (%1)';
				|it = 'Contraenti (%1)';
				|pl = 'Kontrahenci (%1)';
				|tr = 'Cari hesaplar (%1)'"),
			CounterpartiesCount);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdatePageTitleProducts()
	
	GoodsQuantity = Goods.Count();
	
	If GoodsQuantity = 0 Then
		Items.GoodsPage.Title = NStr("vi = 'Hàng hóa và dịch vụ';
									|ru = 'Товары и услуги';
									|en = 'Goods and services'; fa = 'کالاها و خدمات';
									|it = 'Articoli e servizi';
									|pl = 'Towary i usługi';
									|tr = 'Ürünler ve hizmetler'");
	Else
		Items.GoodsPage.Title = StrTemplate(
			NStr("vi = 'Hàng hóa và dịch vụ (%1)';
				|ru = 'Товары и услуги (%1)';
				|en = 'Goods and services (%1)'; fa = 'Goods and services (%1)';
				|it = 'Articoli e servizi (%1)';
				|pl = 'Towary i usługi (%1)';
				|tr = 'Ürünler ve hizmetler (%1)'"),
			GoodsQuantity);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetCounterpartyVisibility()
	
	Items.CounterpartyGroup.Visible =
		Not MultipleCounterparties
		And KeepRecordsOfCounterparties
		And Not KeepRecordsOfParties
		And Not IsRequestForPayment;
		
	Items.CounterpartiesPage.Visible =
		MultipleCounterparties
		And KeepRecordsOfCounterparties
		And Not KeepRecordsOfParties
		And Not IsRequestForPayment;
	
EndProcedure

&AtClient
Procedure UpdateTablePartCounterparties()
	
	Counterparties.Clear();
	
	If ValueIsFilled(Counterparty) Then
		NewRow = Counterparties.Add();
		
		NewRow.Counterparty = Counterparty;
		NewRow.CounterpartyID = CounterpartyID;
		NewRow.CounterpartyType = CounterpartyType;
		
		NewRow.ContactPerson = ContactPerson;
		NewRow.ContactPersonID = ContactPersonID;
		NewRow.ContactPersonType = ContactPersonType;
		
		NewRow.SignedFromCounterparty = SignedFromCounterparty;
		NewRow.SignedFromCounterpartyID = SignedFromCounterpartyID;
		NewRow.SignedFromCounterpartyType = SignedFromCounterpartyType;
	EndIf;
	
EndProcedure

&AtServer
Procedure SynchronizeITCHAttributesCounterparties()
	
	If Counterparties.Count() = 0 Then
		If ValueIsFilled(Counterparty) Then
			NewRow = Counterparties.Add();
			
			NewRow.Counterparty = Counterparty;
			NewRow.CounterpartyID = CounterpartyID;
			NewRow.CounterpartyType = CounterpartyType;
			
			NewRow.ContactPerson = ContactPerson;
			NewRow.ContactPersonID = ContactPersonID;
			NewRow.ContactPersonType = ContactPersonType;
			
			NewRow.SignedFromCounterparty = SignedFromCounterparty;
			NewRow.SignedFromCounterpartyID = SignedFromCounterpartyID;
			NewRow.SignedFromCounterpartyType = SignedFromCounterpartyType;
		EndIf;
	Else
		String = Counterparties[0];
		Counterparty = String.Counterparty;
		CounterpartyID = String.CounterpartyID;
		CounterpartyType = String.CounterpartyType;
		ContactPerson = String.ContactPerson;
		ContactPersonID = String.ContactPersonID;
		ContactPersonType = String.ContactPersonType;
		SignedFromCounterparty = String.SignedFromCounterparty;
		SignedFromCounterpartyID = String.SignedFromCounterpartyID;
		SignedFromCounterpartyType = String.SignedFromCounterpartyType;
	EndIf;
	
EndProcedure

&AtServer
Function ThisObjectBefore(Proxy)
	
	Return IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, ID, Type);
	
EndFunction

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
