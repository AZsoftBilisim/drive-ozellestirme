// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		ReadOnly = True;
	EndIf;
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		Object.ExecutionDate = BegOfDay(CurrentSessionDate());
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_InstructionForShippingAgent", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DeliveryMethodOnChange(Item)
	
	DeliveryMethodWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure LabelBaseClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Object.Basis1.Count() = 1 Then
		ShowValue(,Object.Basis1[0].Basis);
	Else
		
		Basis1 = New Array;
		For Each Page1 In Object.Basis1 Do
			Basis1.Add(Page1.Basis);
		EndDo;
		
		OpenForm("CommonForm.ListOfCustomObjectsERP",
			New Structure("DocumentsArray,FormCaption", Basis1, NStr("vi = 'Căn cứ để giao nhận';
																	|ru = 'Основания поручения экспедитору';
																	|en = 'Base delivery requests'; fa = 'Base delivery requests';
																	|it = 'Motivi di task a spedizioniere';
																	|pl = 'Podstawa zlecenia dla spedytora';
																	|tr = 'Teslimat talebi temeli'")),,,,,,
			FormWindowOpeningMode.LockOwnerWindow);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure AddressOnChange(Item)
	
	ProcessAddressChange(Item, "DeliveryAddress");
	
EndProcedure

&AtClient
Procedure DeliveryAddressClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	GoodsDeliveryClient.ClearAddressPresentation(
		Object.DeliveryAddress,
		Object.DeliveryAddressFieldValues,
		Object.DeliveryAddressValue);
	
EndProcedure

&AtClient
Procedure AddressStartChoice(Item, ChoiceData, StandardProcessing)
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddress");
	
	GoodsDeliveryClient.OpenAddressSelectionFormAndProcessResult(
		Item,
		Object,
		NamesOfDetailsOfDeliveryAddresses,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure PointOnChange(Item)
	
	ItemWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure ItemAddressChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	GoodsDeliveryClient.WhenChangingAddressPresentation(
		Item,
		Object.DeliveryAddress,
		Object.DeliveryAddressFieldValues);
	
	If GoodsDeliveryClientServer.AdditionalInfoChangedByUser(Items, Object)
	   And ValueSelected.Property("AdditionalDeliveryInformation") Then
		FillPropertyValues(Object, ValueSelected, , "AdditionalDeliveryInformation");
	Else
		FillPropertyValues(Object, ValueSelected);
	EndIf;
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure PointStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ShowChooseFromList(New CallbackDescription("ItemStartSelectionStartSelectionEnd", ThisObject), PointsSelectionList, Item);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Object.ExecutionDate < Object.Date Then
		Object.ExecutionDate = Object.Date;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtClient
Procedure SupplementDeliveryInformationWithContacts(Command)
	
	AddDeliveryInformationWithContactsOnServer();
	
EndProcedure

&AtClient
Procedure AddDescriptionWithBases(Command)
	
	SupplementDescriptionWithBasesOnServer();
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	If Not ValueIsFilled(Object.EmployeeResponsible) Then
		Object.EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
	PointsSelectionList.Clear();
	If AccessRight("Read", Metadata.Catalogs.Partners) Then
		PointsSelectionList.Add(NStr("vi = '<chọn đối tác>';
									|ru = '<выбрать партнера>';
									|en = '<select a partner>'; fa = '<select a partner>';
									|it = '<selezionare partner>';
									|pl = '<wybierz partnera>';
									|tr = '<iş ortağı seç>'"));
	EndIf;
	PointsSelectionList.Add(NStr("vi = '<chọn bộ phận>';
								|ru = '<выбрать подразделение>';
								|en = '<select a business unit>'; fa = '<select a business unit>';
								|it = '<selezionare reparto>';
								|pl = '<wybierz dział>';
								|tr = '<departmanı seç>'"));
	PointsSelectionList.Add(NStr("vi = '<chọn kho>';
								|ru = '<выбрать склад>';
								|en = '<select a warehouse>'; fa = '<select a warehouse>';
								|it = '<selezionare magazzino>';
								|pl = '<wybierz magazyn>';
								|tr = '<ambarı seç>'"));
	PointsSelectionList.Add(NStr("vi = '<nhập văn bản tùy ý>';
								|ru = '<ввести произвольный текст>';
								|en = '<enter custom text>'; fa = '<enter custom text>';
								|it = '<inserire testo libero>';
								|pl = '<wprowadź dowolny tekst>';
								|tr = '<keyfi metin gir>'"));
	
	If Object.Basis1.Count() > 0 Then
		BaseData = Documents.InstructionForShippingAgent.BaseData(Object.Basis1.Unload().UnloadColumn("Basis"));
		
		For Each Value In BaseData.Items_2 Do
			If TypeOf(Value) = Type("String") Then
				ObjectPresentation = NStr("vi = 'Nội dung';
											|ru = 'Текст';
											|en = 'Text'; fa = 'متن';
											|it = 'Testo';
											|pl = 'Tekst';
											|tr = 'Metin'");
			Else
				ObjectPresentation = Value.Metadata().ObjectPresentation;
			EndIf;
			
			ValuePresentation = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1: %2';
																								|ru = '%1: %2';
																								|en = '%1: %2'; fa = '%1: %2';
																								|it = '%1: %2';
																								|pl = '%1: %2';
																								|tr = '%1: %2'"),
				ObjectPresentation, Value);
			PointsSelectionList.Add(Value, ValuePresentation);
		EndDo;
		Items.Warehouse.ChoiceList.LoadValues(BaseData.Warehouses);
		Items.ContactPerson.ChoiceList.LoadValues(BaseData.Contacts);
	Else
		Items.LabelBase.Visible = False;
	EndIf;
	
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object);
	
	If Not ValueIsFilled(Object.Ref)
		And Not ValueIsFilled(Object.DeliveryAddress)
		And ValueIsFilled(Object.Point)
		And Items.ItemAddress.ChoiceList.Count() > 0 Then
		
		FirstStructureInList = Items.ItemAddress.ChoiceList[0].Value;
		FillPropertyValues(Object, FirstStructureInList);
		
	EndIf;
	
	SetItemsAvailability();
	DisplayBase();
	DeliveryMethodWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure DeliveryMethodWhenChangedOnServer()
	
	If Object.DeliveryMethod = Enums.TransportMethods.InstructionForShippingAgentFromWarehouse Then
		Items.TitleFromWhere.Visible = True;
		Items.IndentFromWhere.Visible    = True;
		Items.Warehouse.Visible           = True;
		Items.HeadingWarehouse.Visible  = True;
		Items.TitleFromWhere.Title = NStr("vi = 'Địa chỉ gửi';
											|ru = 'Откуда';
											|en = 'From'; fa = 'از';
											|it = 'Da dove';
											|pl = 'From';
											|tr = 'Nereden'");
		Items.HeadingToWhere.Title   = NStr("vi = 'Địa chỉ nhận';
											|ru = 'Куда';
											|en = 'To'; fa = 'به';
											|it = 'Dove (destinazione)';
											|pl = 'To';
											|tr = 'Nereye'");
	ElsIf Object.DeliveryMethod = Enums.TransportMethods.InstructionForShippingAgentToWarehouse Then
		Items.TitleFromWhere.Visible = True;
		Items.IndentFromWhere.Visible    = True;
		Items.Warehouse.Visible           = True;
		Items.HeadingWarehouse.Visible  = True;
		Items.TitleFromWhere.Title = NStr("vi = 'Địa chỉ nhận';
											|ru = 'Куда';
											|en = 'To'; fa = 'به';
											|it = 'Dove (destinazione)';
											|pl = 'Dokąd';
											|tr = 'Nereye'");
		Items.HeadingToWhere.Title   = NStr("vi = 'Địa chỉ gửi';
											|ru = 'Откуда';
											|en = 'From'; fa = 'از';
											|it = 'Da dove';
											|pl = 'Skąd';
											|tr = 'Nereden'");
	Else
		Items.TitleFromWhere.Visible = False;
		Items.IndentFromWhere.Visible    = False;
		Items.Warehouse.Visible           = False;
		Items.HeadingWarehouse.Visible  = False;
		Items.HeadingToWhere.Title   = NStr("vi = 'Ở đâu';
											|ru = 'Где';
											|en = 'Where'; fa = 'کجا';
											|it = 'Dove';
											|pl = 'Gdzie';
											|tr = 'Nerede'");
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayBase()
	
	If Object.Basis1.Count() = 0 Then
		
		Items.LabelBase.Title = NStr("vi = 'Cơ sở';
									|ru = 'Основание';
									|en = 'Base document'; fa = 'سند مبنا';
									|it = 'Causale';
									|pl = 'Podstawa';
									|tr = 'Esas'");
		LabelBase = NStr("vi = '<Thêm>';
						|ru = '<Добавить>';
						|en = '<Add>'; fa = '<Add>';
						|it = '<Aggiungere>';
						|pl = '<Dodaj>';
						|tr = '<Ekle>'");
		
	ElsIf Object.Basis1.Count() = 1 Then
		
		Items.LabelBase.Title = NStr("vi = 'Cơ sở';
									|ru = 'Основание';
									|en = 'Base document'; fa = 'سند مبنا';
									|it = 'Causale';
									|pl = 'Podstawa';
									|tr = 'Esas'");
		LabelBase = String(Object.Basis1[0].Basis);
		
	Else
		
		Items.LabelBase.Title = NStr("vi = 'Cơ sở';
									|ru = 'Основания';
									|en = 'Base documents'; fa = 'اسناد مبنا';
									|it = 'Causali';
									|pl = 'Podstawy';
									|tr = 'Temel'");
		
		BaseTemplate = NStr("vi = 'Tổng chứng từ: %1';
							|ru = 'Всего документов: %1';
							|en = 'Total documents: %1'; fa = 'Total documents: %1';
							|it = 'Всего документов: %1';
							|pl = 'Razem dokumentów: %1';
							|tr = 'Toplam belgeler: %1'");
		LabelBase = StringFunctionsClientServer.SubstituteParametersToString(
			BaseTemplate,
			String(Object.Basis1.Count()));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AddDeliveryInformationWithContactsOnServer()
	
	GoodsDelivery.SupplementDeliveryInformationWithContacts(Object);
	
EndProcedure

&AtServer
Procedure SupplementDescriptionWithBasesOnServer()
	
	Basis1 = Object.Basis1.Unload().UnloadColumn("Basis");
	BasesByType = TMCommonUse.DecomposeArrayOfReferencesByType(Basis1);
	For Each KeyAndValue In BasesByType Do
		TextBase = String(KeyAndValue.Key) + ": ";
		If KeyAndValue.Key = Type("String") Then
			TextBase = KeyAndValue.Value + ".";
		Else
			Attributes = Common.ObjectsAttributesValues(KeyAndValue.Value, "Number, Date");
			TextBase = String(KeyAndValue.Key) + ?(KeyAndValue.Value.Count()>1,": "," ");
			For Each KeyAndValueOfBankingDetails In Attributes Do
				TextNumberAndDate = NStr("vi = '%Number% ngày %Date%,';
										|ru = '%Number% от %Date%,';
										|en = '%Number% dated %Date%,'; fa = '%Number% dated %Date%,';
										|it = '%Number% del %Date%,';
										|pl = '%Number% od %Date%,';
										|tr = '%Date%''dan %Number%.'") + " ";
				TextNumberAndDate = StrReplace(TextNumberAndDate, "%Number%",
					ObjectsPrefixesClientServer.NumberForPrinting(KeyAndValueOfBankingDetails.Value.Number));
				TextNumberAndDate = StrReplace(TextNumberAndDate, "%Date%",
					Format(KeyAndValueOfBankingDetails.Value.Date,"DF=MM/dd/yy"));
				TextBase = TextBase + TextNumberAndDate;
			EndDo;
			TextBase = Left(TextBase, StrLen(TextBase)-2) + ".";
		EndIf;
		If StrFind(Object.SpecialTransportationConditionsDescription, TextBase) = 0 Then
			If Not IsBlankString(Object.SpecialTransportationConditionsDescription) Then
				Object.SpecialTransportationConditionsDescription = Object.SpecialTransportationConditionsDescription + Chars.LF;
			EndIf;
			Object.SpecialTransportationConditionsDescription = Object.SpecialTransportationConditionsDescription + TextBase;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure ItemWhenChangingOnServer()
	
	Items.ItemAddress.ChoiceList.Clear();
	EmptyAttributes = GoodsDeliveryClientServer.GetEmptyStructureOfDeliveryDetails(Object);
	FillPropertyValues(Object, EmptyAttributes,,"DeliveryMethod,AdditionalDeliveryInformation");
	
	If ValueIsFilled(Object.Point) Then
		
		GoodsDelivery.FillInListsForSelectingRecipientSenderAddresses(Items, Object);
		If Items.ItemAddress.ChoiceList.Count() > 0 Then
			FirstStructureInList = Items.ItemAddress.ChoiceList[0].Value;
			
			If GoodsDeliveryClientServer.AdditionalInfoChangedByUser(Items, Object) Then
				FillPropertyValues(Object, FirstStructureInList,
					"DeliveryAddress, DeliveryAddressFieldValues, DeliveryZone, DeliveryTimeFrom, DeliveryTimeTo");
			Else
				FillPropertyValues(Object, FirstStructureInList);
			EndIf;
			
		EndIf;
				
	EndIf;
	
	CheckFillInContactPerson();
	
	SetItemsAvailability();
	
EndProcedure

&AtServer
Procedure SetItemsAvailability()
	
	Items.ContactPerson.Enabled = (TypeOf(Object.Point) = Type("CatalogRef.Partners"));
	Items.SupplementDeliveryInformationWithContacts.Enabled =
		(TypeOf(Object.Point) <> Type("CatalogRef.BusinessStructure")
		And TypeOf(Object.Point) <> Type("String"));
	Items.AddDescriptionWithBases.Enabled = (Object.Basis1.Count() > 0);
	
EndProcedure

&AtServer
Procedure CheckFillInContactPerson()
	
	If TypeOf(Object.Point) <> Type("CatalogRef.Partners") Then
		Object.ContactPerson = Catalogs.ContactPersonsForPartners.EmptyRef();
		Return;
	EndIf;
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Object.Point, Object.ContactPerson);
	
EndProcedure

&AtClient
Procedure ItemStartSelectionStartSelectionEnd(SelectedElement, AdditionalParameters) Export
	
	If SelectedElement = Undefined Then
		Return;
	EndIf;
	
	ValueSelected = SelectedElement.Value;
	CallbackDescription = New CallbackDescription("AfterSelectingItem",ThisObject);
	If ValueSelected = Undefined Then
		Return;
	ElsIf ValueSelected = NStr("vi = '<chọn đối tác>';
								|ru = '<выбрать партнера>';
								|en = '<select a partner>'; fa = '<select a partner>';
								|it = '<selezionare partner>';
								|pl = '<wybierz partnera>';
								|tr = '<iş ortağı seç>'") Then
		OpenForm("Catalog.Partners.Form.ChoiceForm",            , ThisObject,,,,CallbackDescription,FormWindowOpeningMode.LockOwnerWindow);	
	ElsIf ValueSelected = NStr("vi = '<chọn bộ phận>';
								|ru = '<выбрать подразделение>';
								|en = '<select a business unit>'; fa = '<select a business unit>';
								|it = '<selezionare reparto>';
								|pl = '<wybierz dział>';
								|tr = '<departmanı seç>'") Then
		OpenForm("Catalog.BusinessStructure.Form.ChoiceForm",, ThisObject,,,,CallbackDescription,FormWindowOpeningMode.LockOwnerWindow);
	ElsIf ValueSelected = NStr("vi = '<chọn kho>';
								|ru = '<выбрать склад>';
								|en = '<select a warehouse>'; fa = '<select a warehouse>';
								|it = '<selezionare magazzino>';
								|pl = '<wybierz magazyn>';
								|tr = '<ambarı seç>'") Then
		OpenForm("Catalog.Warehouses.Form.ChoiceForm",              , ThisObject,,,,CallbackDescription,FormWindowOpeningMode.LockOwnerWindow);
	ElsIf ValueSelected = NStr("vi = '<nhập văn bản tùy ý>';
								|ru = '<ввести произвольный текст>';
								|en = '<enter custom text>'; fa = '<enter custom text>';
								|it = '<inserire testo libero>';
								|pl = '<wprowadź dowolny tekst>';
								|tr = '<keyfi metin gir>'") Then
		Object.Point = "";
	Else
		Object.Point = ValueSelected;
	EndIf;
	
	ItemWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure AfterSelectingItem(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	Object.Point = ValueSelected;
	ItemWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure ProcessAddressChange(Item, NameOfAddressDetails)
	
	AttributesNames = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses(NameOfAddressDetails);
	
	If IsBlankString(Object[AttributesNames.NameOfDetailsOfDeliveryAddress]) Then
		
		GoodsDeliveryClient.ClearAddressPresentation(
			Object[AttributesNames.NameOfDetailsOfDeliveryAddress],
			Object[AttributesNames.AttributeNameOfDeliveryAddressFieldValues],
			Object[AttributesNames.NameOfAttributeOfDeliveryAddressValue]);
		
	Else
		
		GoodsDeliveryClient.WhenChangingAddressPresentation(
			Item,
			Object[AttributesNames.NameOfDetailsOfDeliveryAddress],
			Object[AttributesNames.NameOfAttributeOfDeliveryAddressValue]);
		
		DeliveryAddressOnChangeATServer(
			Object[AttributesNames.NameOfDetailsOfDeliveryAddress],
			Object[AttributesNames.NameOfAttributeOfDeliveryAddressValue],
			Object[AttributesNames.AttributeNameOfDeliveryAddressFieldValues]);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DeliveryAddressOnChangeATServer(Address, AddressValue, FieldValueAddress)
	
	CustomFormatAddress = ContactsManager.AddressEnteredInFreeFormat(AddressValue);
	If Not CustomFormatAddress Then
		
		CountryData1 = ContactsManager.ContactInformationAddressCountry(AddressValue);
		
		NewAddressStructure = ContactsManager.InfoAboutAddress();
		NewAddressStructure.Presentation = Address;
		NewAddressStructure.Country = CountryData1.Description;
		NewAddressStructure.CountryCode = CountryData1.Code;
		
		AddressValue = ContactsManager.ContactInformationInJSON(
			NewAddressStructure,
			Enums.ContactInformationTypes.Address);
		
		SetAddressTypeInFreeForm(AddressValue);
		
	EndIf;
	
	FieldValueAddress = ContactsManager.ContactInformationToXML(
		AddressValue,
		Address,
		Enums.ContactInformationTypes.Address);
	
EndProcedure

&AtServerNoContext
Procedure SetAddressTypeInFreeForm(DeliveryAddressValue)
	
	StringTypeToReplace = """addressType"": ""Administrative-territorial""";
	StringIsFreeType = """addressType"": ""FreeForm""";
	DeliveryAddressValue = StrReplace(DeliveryAddressValue, StringTypeToReplace, StringIsFreeType);
	
EndProcedure

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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
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
