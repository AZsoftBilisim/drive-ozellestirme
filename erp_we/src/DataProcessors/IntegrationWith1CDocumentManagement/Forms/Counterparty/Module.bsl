#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ID = Parameters.id;
	Type = Parameters.type;
	If Not ValueIsFilled(Type) Then
		Type = "DMCorrespondent";
	EndIf;
	
	Parameters.Property("ExternalObject", ExternalObject);
	
	LegalEntityValue = "ЮрЛицо"; //@NON-NLS-1
	MeaningPhysical = "ФизЛицо"; //@NON-NLS-1
	ValueOfTheSoleProprietor = "ИндивидуальныйПредприниматель"; //@NON-NLS-1
	NonResidentValue = "ЮрЛицоНеРезидент"; //@NON-NLS-1
	
	If IntegrationWith1CDocumentManagementCached.UseTermCorrespondents() Then
		Items.SceneryLegalEntity.Title = NStr("vi = 'Dạng đối tác';
												|ru = 'Вид корреспондента';
												|en = 'Correspondent kind'; fa = 'Correspondent kind';
												|it = 'Tipo di corrispondente';
												|pl = 'Rodzaj korespondenta';
												|tr = 'Muhabir türü'");
	EndIf;
	
	// read document data
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	If ValueIsFilled(ID) And ValueIsFilled(Type) Then
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRetrieveRequest");
		ListOfObjects = Query.objectIDs; // XDTOList
		ListOfObjects.Add(
			IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				ID,
				Type));
		
		Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
		
		XDTODataObject = Result.objects[0];
		
		If IntegrationWith1CDocumentManagementCached.UseTermCorrespondents() Then
			Title = StrTemplate(NStr("vi = '%1 (Đối tác)';
									|ru = '%1 (Корреспондент)';
									|en = '%1 (Correspondent) '; fa = '%1 (Correspondent) ';
									|it = '%1 (Corrispondente)';
									|pl = '%1 (Korespondent)';
									|tr = '%1 (Muhabir)'"), XDTODataObject.name);
		Else
			Title = StrTemplate(NStr("vi = '%1 (Đối tác)';
									|ru = '%1 (Контрагент)';
									|en = '%1 (Counterparty)'; fa = '%1 (Counterparty)';
									|it = '%1 (Controparte)';
									|pl = '%1 (Kontrahent)';
									|tr = '%1 (Cari hesap)'"), XDTODataObject.name);
		EndIf;
		
		If Not ValueIsFilled(ExternalObject) Then
			ExternalObjects = IntegrationWith1CDocumentManagementCore.LinksToExternalObjects(XDTODataObject);
			If ExternalObjects.Count() <> 0 Then
				ExternalObject = ExternalObjects[0];
			EndIf;
		EndIf;
		
	Else
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetNewObjectRequest");
		Query.type = Type;
		
		Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
		
		XDTODataObject = Result;
		
		If IntegrationWith1CDocumentManagementCached.UseTermCorrespondents() Then
			Title = NStr("vi = 'Đối tác (tạo mới)';
						|ru = 'Корреспондент (создание)';
						|en = 'Correspondent (creation)'; fa = 'Correspondent (creation)';
						|it = 'Corrispondente (creazione)';
						|pl = 'Korespondent (tworzenie)';
						|tr = 'Muhabir (oluşturma)'");
		Else
			Title = NStr("vi = 'Đối tác (tạo mới)';
						|ru = 'Контрагент (создание)';
						|en = 'Counterparty (Create)'; fa = 'Counterparty (Create)';
						|it = 'Contraente (creazione)';
						|pl = 'Kontrahent (tworzenie)';
						|tr = 'Cari hesap (oluşturma)'");
		EndIf;
		
	EndIf;
	
	// transfer data to the form
	ReadObjectIntoForm(XDTODataObject);
	
	If Not ValueIsFilled(ID)
			And ValueIsFilled(ExternalObject)
			And ValueIsFilled(Parameters.Rule) Then
		
		Catalogs.RulesForIntegrationWith1CDocumentManagement.FillInMapItemFormUpToRule(
			ExternalObject, ThisObject, Parameters.Rule);
		IntegrationWith1CDocumentManagementCoreOverridable.FillOutFormFromConsumer(
			ExternalObject, ThisObject);
		
		// Correction of legal / physical faces.
		If LegalEntityIndividual = NStr("vi = 'Cá nhân';
										|ru = 'Физическое лицо';
										|en = 'Person'; fa = 'شخص';
										|it = 'Persona fisica';
										|pl = 'Osoba fizyczna';
										|tr = 'Gerçek kişi'") Then
			LegalEntityIndividualID = "ФизЛицо"; //@NON-NLS-1
			LegalEntityIndividualType = "DMLegalPrivatePerson";
		ElsIf LegalEntityIndividual = NStr("vi = 'Pháp nhân';
											|ru = 'Юридическое лицо';
											|en = 'Legal entity'; fa = 'شخص حقوقی';
											|it = 'Ente giuridico';
											|pl = 'Osoba prawna';
											|tr = 'Tüzel kişi'") Then
			LegalEntityIndividualID = "ЮрЛицо"; //@NON-NLS-1
			LegalEntityIndividualType = "DMLegalPrivatePerson";
		ElsIf LegalEntityIndividual = NStr("vi = 'Cá nhân kinh doanh';
											|ru = 'Индивидуальный предприниматель';
											|en = 'Individual entrepreneur'; fa = 'کارآفرین انفرادی';
											|it = 'Imprenditore individuale';
											|pl = 'Przedsiębiorca indywidualny';
											|tr = 'Şahıs şirketi'") Then
			LegalEntityIndividualID = "ИндивидуальныйПредприниматель"; //@NON-NLS-1
			LegalEntityIndividualType = "DMLegalPrivatePerson";
		ElsIf LegalEntityIndividual = NStr("vi = 'Không phải cá nhân lưu trú';
											|ru = 'Не резидент';
											|en = 'Non-resident'; fa = 'Non-resident';
											|it = 'Non residente';
											|pl = 'Nie jest rezydentem';
											|tr = 'Yerleşik olmayan'") Then
			LegalEntityIndividualID = "ЮрЛицоНеРезидент"; //@NON-NLS-1
			LegalEntityIndividualType = "DMLegalPrivatePerson";
		EndIf;
		
	EndIf;
	
	If Parameters.ReadOnly = True Then
		ReadOnly = True;
	EndIf;
	
	UpdateScenery();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "DocumentManagement_SelectAValueFromTheDropDownListCompletion" And Source = ThisObject Then
		If Parameter.Attribute = "LegalEntityIndividual" And LegalEntityIndividualID <> OriginalLegalEntityID Then
			SetVisibility1();
			UpdateAdditionalAttributesItems();
			OriginalLegalEntityID = LegalEntityIndividualID;
		EndIf;
		
	ElsIf EventName = "DocumentManagement_AddingALink" And Parameter.ID = ID Then
		ExternalObject = Parameter.Object;
		UpdateScenery();
		
	ElsIf EventName = "DocumentManagement_DeletingALink" And Parameter.ID = ID Then
		ExternalObject = Undefined;
		UpdateScenery();
		
	ElsIf EventName = "Recording_1CDocumentManagementObject" And Parameter.ID = ID Then
		UpdateScenery();
		
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
			Notification, Cancel, Exit,,WarningText);
		
	Else
		
		Cancel = True;
		AttachIdleHandler("CloseWithParameter", 0.1, True);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetVisibility1();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

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
					|%1 için uygunluğu temizle? '"),String(ExternalObject));
	
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes,NStr("vi = 'Xóa';
											|ru = 'Очистить';
											|en = 'Clear'; fa = 'پاک کردن';
											|it = 'Cancellare';
											|pl = 'Clear';
											|tr = 'Temizle'"));
	Buttons.Add(DialogReturnCode.No,NStr("vi = 'Không xóa';
										|ru = 'Не очищать';
										|en = 'Do not clean up'; fa = 'پاک‌سازی نشود';
										|it = 'Non cancellare';
										|pl = 'Nie oczyszczaj';
										|tr = 'Temizlememek'"));
	
	ShowQueryBox(Notification, QueryText, Buttons,, DialogReturnCode.No);
	
EndProcedure

&AtClient
Procedure LegalEntityIndividualOnChange(Item)
	
	If LegalEntityIndividualID <> OriginalLegalEntityID Then
		
		SetVisibility1();
		
		// Handler of the "Properties" mechanism
		UpdateAdditionalAttributesItems();
		
		OriginalLegalEntityID = LegalEntityIndividualID;
	EndIf;
	
EndProcedure

&AtClient
Procedure LegalEntityIndividualStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheDropDownList("DMLegalPrivatePerson", "LegalEntityIndividual",
		ThisObject,,,Items.LegalEntityIndividual);
	
EndProcedure

&AtClient
Procedure LegalEntityIndividualTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMLegalPrivatePerson", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"LegalEntityIndividual", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure LegalEntityIndividualAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMLegalPrivatePerson",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure LegalEntityIndividualChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"LegalEntityIndividual", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure DescriptionOnChange(Item)
	
	If Not ValueIsFilled(FullDescr) Then
		FullDescr = Description;
	EndIf;
	
	Presentation = Description;
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectUserFromUnitTree("EmployeeResponsible", ThisObject);
	
EndProcedure

&AtClient
Procedure PhysicalStartOfSelection(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheList("DMPrivatePerson", "Person", ThisObject);
	
EndProcedure

&AtClient
Procedure PhysicalSelectionProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Person", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure PhysicalPersonAutoSelection(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMPrivatePerson",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure PhysicalEndOfTextInput(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching("DMPrivatePerson", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Person", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching("DMUser", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"EmployeeResponsible", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMUser",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"EmployeeResponsible", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProperties

&AtClient
Procedure PropertiesValuePresentationStartSelection(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.SelectValueOfAdditionalProps(
		ThisObject,
		Item,
		StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteExecute(Command)
	
	WriteObject();
	Modified = False;
	IntegrationWith1CDocumentManagementClient.Notify_ObjectRecord(ThisObject, ExternalObject);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	WriteObject();
	Modified = False;
	IntegrationWith1CDocumentManagementClient.Notify_ObjectRecord(ThisObject, ExternalObject);
	Close();
	
EndProcedure

&AtClient
Procedure Send(Command)
	
	If ValueIsFilled(ID) Then
		IntegrationWith1CDocumentManagementClient.CreateABusinessProcessByTheObjectDM(ID, Type, Description, ExternalObject);
	Else
		Notification = New CallbackDescription("CreateBusinessProcessCompletion", ThisObject);
		QueryText = NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
							|Chỉ có thể tạo mới quy trình nghiệp vụ sau khi ghi lại dữ liệu.
							|Dữ liệu sẽ được ghi lại.';
							|ru = 'Данные еще не записаны.
							|Создание бизнес-процесса возможно только после записи данных.
							|Данные будут записаны.';
							|en = 'Data has not been written yet.
							|You can create a business process only after the data is written.
							|Data will be written.'; fa = 'Data has not been written yet.
							|You can create a business process only after the data is written.
							|Data will be written.';
							|it = 'Dati non ancora registrati.
							|È possibile creare un processo aziendale solo dopo la registrazione dei dati.
							|I dati saranno registrati.';
							|pl = 'Dane nie są jeszcze zapisane.
							|Tworzenie procesu biznesowego jest możliwe tylko po zapisywaniu danych.
							|Dane zostaną zapisane.';
							|tr = 'Veriler kaydedilmedi.
							|İş sürecinin oluşturulması ancak veriler yazıldıktan sonra mümkündür.
							|Veriler yazılacaktır.'");
		Buttons = QuestionDialogMode.OKCancel;
		ShowQueryBox(Notification, QueryText, Buttons, 0);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure BeforeCloseCompletion(Response, NotificationParameters) Export
	
	WriteObject();
	IntegrationWith1CDocumentManagementClient.Notify_ObjectRecord(ThisObject, ExternalObject);
	CloseWithParameter();
	
EndProcedure

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

&AtClient
Procedure SelectLinkPressEndSelection(Result, NotificationParameters) Export
	
	If Result <> Undefined Then
		IntegrationWith1CDocumentManagementCoreServerCall.AddLink(ID, Type, Result);
		IntegrationWith1CDocumentManagementCoreClient.Notify_AddingConnection(ID, Type, Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure LinkClearClickCompletion(Response, NotificationParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		CacheExternalObject = ExternalObject;
		DeleteConnectionOnServer();
		IntegrationWith1CDocumentManagementCoreClient.Notify_RemovingLink(ID, Type, CacheExternalObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateBusinessProcessCompletion(Response, NotificationParameters) Export
	
	If Response = DialogReturnCode.OK Then
		WriteExecute(Undefined);
		IntegrationWith1CDocumentManagementClient.CreateABusinessProcessByTheObjectDM(ID, Type, Description, ExternalObject);
	EndIf;
	
EndProcedure

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

&AtServer
Procedure ReadObjectIntoForm(XDTODataObject)
	
	// Filling in Bank details
	Presentation = XDTODataObject.objectID.presentation;
	TIN = XDTODataObject.inn;
	CRTR = XDTODataObject.kpp;
	NCBOCode = XDTODataObject.okpo;
	If XDTODataObject.Properties().Get("registrationNumber") = Undefined Then
		Items.RegistrationNumber.Visible = False;
		Items.RegistrationNumber2.Visible = False;
		Items.RegistrationNumber3.Visible = False;
	Else
		RegistrationNumber = XDTODataObject.registrationNumber;
	EndIf;
	
	Comment = XDTODataObject.comment;
	FullDescr = XDTODataObject.fullName;
	Description = XDTODataObject.name;
	
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
		XDTODataObject.legalPrivatePerson, "LegalEntityIndividual", False);
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
		XDTODataObject.privatePerson, "Person", False);
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
		XDTODataObject.responsible, "EmployeeResponsible", False);
	
	OriginalLegalEntityID = LegalEntityIndividualID;
	
	// additional banking details
	DataProcessors.IntegrationWith1CDocumentManagementCore.PlaceAdditionalDetailsOnForm(
		ThisObject,
		XDTODataObject);
	DataProcessors.IntegrationWith1CDocumentManagementCore.SetNavigationLink(
		ThisObject,
		XDTODataObject);
	
	If ValueIsFilled(ID) Then
		FillingRules = IntegrationWith1CDocumentManagement.RulesForFillingIntegratedObjectsWithList(XDTODataObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	DataProcessors.IntegrationWith1CDocumentManagementCore.GetAdditionalDetailsAndPlaceThemOnForm(
		Proxy,
		ThisObject);
	
EndProcedure

&AtClient
Procedure SetVisibility1()
	
	If LegalEntityIndividualID = MeaningPhysical Then
		Items.LegalEntityGroupIndividual.CurrentPage = Items.GroupAsIndividual;
	ElsIf LegalEntityIndividualID = ValueOfTheSoleProprietor Then
		Items.LegalEntityGroupIndividual.CurrentPage = Items.GroupAsSoleProprietor;
	ElsIf LegalEntityIndividualID = NonResidentValue Then
		Items.LegalEntityGroupIndividual.CurrentPage = Items.GroupAsNonResident;
	Else
		Items.LegalEntityGroupIndividual.CurrentPage = Items.GroupAsLegalEntity;
	EndIf;
	
EndProcedure

&AtServer
Procedure WriteObject()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	XDTODataObject = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMCorrespondent",
		ExternalObject);
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.GenerateAdditionalProperties(
		Proxy,
		XDTODataObject,
		ThisObject);
	
	MatchingBankDetails = NewMatchingOfXdtPropertiesAndObjectDetails();
	
	For Each MapRow In MatchingBankDetails Do
		If TypeOf(MapRow.Value) = Type("String") Then
			IntegrationWith1CDocumentManagement.FillInXDTPropertyOfOizPropsStructure(
				Proxy,
				XDTODataObject,
				MapRow.Value,
				ThisObject,
				MapRow.Key);
		Else
			XDTOList = XDTODataObject[MapRow.Value.Name]; // XDTOList
			For Each String In ThisObject[MapRow.Key] Do
				XDTORow = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, MapRow.Value.Type);
				For Each TSMatchString In MapRow.Value.Attributes Do
					IntegrationWith1CDocumentManagement.FillInXDTPropertyOfOizPropsStructure(
						Proxy,
						XDTORow,
						TSMatchString.Value,
						String,
						TSMatchString.Key);
				EndDo;
				XDTOList.Add(XDTORow);
			EndDo;
		EndIf;
	EndDo;
	
	XDTODataObject.name = Description;
	
	If ValueIsFilled(ID) And ValueIsFilled(Type) Then // Update.
		
		XDTODataObject.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, ID, Type);
		
		Result = IntegrationWith1CDocumentManagementCore.WriteObject(Proxy, XDTODataObject);
		
		XDTODataObject = Result.objects[0];
		
	Else // Creation.
		
		XDTODataObject.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy);
		
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMCreateRequest");
		Query.object = XDTODataObject;
		
		Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
		
		XDTODataObject = Result.object;
		ID = XDTODataObject.objectID.ID;
		Type = XDTODataObject.objectID.type;
		
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
	
	// Re-read the object into the Form.
	ReadObjectIntoForm(XDTODataObject);
	
EndProcedure

&AtServer
Function NewMatchingOfXdtPropertiesAndObjectDetails()
	
	MatchingBankDetails = New Map;
	MatchingBankDetails.Insert("Description", "name");
	MatchingBankDetails.Insert("LegalEntityIndividual", "legalPrivatePerson");
	MatchingBankDetails.Insert("TIN", "inn");
	MatchingBankDetails.Insert("CRTR", "kpp");
	MatchingBankDetails.Insert("NCBOCode", "okpo");
	MatchingBankDetails.Insert("RegistrationNumber", "registrationNumber");
	MatchingBankDetails.Insert("Comment", "comment");
	MatchingBankDetails.Insert("FullDescr", "fullName");
	MatchingBankDetails.Insert("Person", "privatePerson");
	MatchingBankDetails.Insert("EmployeeResponsible", "responsible");
	
	Return MatchingBankDetails;
	
EndFunction

&AtServer
Procedure DeleteConnectionOnServer()
	
	IntegrationWith1CDocumentManagementCoreServerCall.DeleteLink(ID, Type, ExternalObject);
	ExternalObject = Undefined;
	UpdateScenery();
	
EndProcedure

&AtServer
Procedure UpdateScenery()
	
	DocumentFilledIn_ = ValueIsFilled(ExternalObject);
	
	If DocumentFilledIn_ Then
		
		ObjectMetadata = ExternalObject.Metadata();
		If Common.IsDocument(ObjectMetadata) Then
			ExternalObjectPresentation = String(ExternalObject);
		Else
			ExternalObjectPresentation = StrTemplate("%1 (%2)", String(ExternalObject), ObjectMetadata.Presentation());
		EndIf;
		
	EndIf;
	
	Items.LinkObject.Visible = DocumentFilledIn_;
	Items.LinkClear.Visible = DocumentFilledIn_;
	
	Items.SelectLink.Visible = Not DocumentFilledIn_;
	
	Items.SVYAZGroup.Visible = (ID <> "");
	
	If Not DocumentFilledIn_ Then
		
		If FillingRules.Count() > 0 Then
			ObjectCreationIsPossible = True;
		Else
			ObjectCreationIsPossible = False;
		EndIf;
		
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

#EndRegion