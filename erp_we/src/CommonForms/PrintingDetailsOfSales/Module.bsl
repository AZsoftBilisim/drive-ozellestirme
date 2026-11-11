
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ItemArray = New Array();
	FillPropertyValues(ThisObject, Parameters,,"CloseOnChoice,CloseOnOwnerClose,PurposeUseKey, PrintBasisTable");
	
	ReFillInDeliveryAddress = GoodsDelivery.ReFillInDeliveryAddressInSalesDocument(Ref);
	
	If ReadOnly Then
		
		ParametersStructure = AttributesToChange(Parameters);
		ItemArray = New Array();
		
		For Each StructureItem In ParametersStructure Do
			ItemArray.Add(StructureItem.Key);
		EndDo;
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", True);
		
	EndIf;
	
	If Parameters.DoNotShowBankDetails <> Undefined Then
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, Parameters.DoNotShowBankDetails, "Visible", False);
	EndIf;
	
	If Parameters.ObjectType = "IntercompanyGoodsReturn"
		Or Parameters.ObjectType = "CustomerInvoiceIntercompany" Then
		TMCommonUseClientServer.SetFormItemProperty(Items, "RecipientCompanyBankAccount", "Visible", Parameters.PaymentsThroughTheOrganization);
		TMCommonUseClientServer.SetFormItemProperty(Items, "CounterpartyBankAccount", "Visible", Not Parameters.PaymentsThroughTheOrganization);
	Else
		If ValueIsFilled(Parameters.PrintBasisTable) Then 
			PrintBasisTable.Load(Parameters.PrintBasisTable.Unload());
		EndIf;
	EndIf;
	
	If GetFunctionalOption("UseDeliveryManagement")
		And Not ReFillInDeliveryAddress
		And Not OrderSales
		And (Parameters.ObjectType = "CustomerInvoice"
			Or Parameters.ObjectType = "TransferOfGoodsToBailee"
			Or (Parameters.ObjectType = "SalesWizard"
				And Parameters.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale))
		Or Parameters.ObjectType = "ReturnOfGoodsToVendor"
		Or Parameters.ObjectType = "RedemptionOfGoodsByCustodian"
		Or Parameters.ObjectType = "ReturnablePackagingRedemptionByCustomer" Then
		
		TMCommonUseClientServer.SetFormItemProperty(Items, "DeliveryAddress", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "SceneryIndentLeft", "Visible", False);
		
	EndIf;
	
	If Parameters.ObjectType = "CustomerInvoiceServices" Then
		Title = NStr("vi = 'Mục tin in';
					|ru = 'Реквизиты печати';
					|en = 'Print details'; fa = 'جزئیات چاپ';
					|it = 'Requisiti di stampa';
					|pl = 'Atrybuty drukowania';
					|tr = 'Yazdırma öznitelikleri'");
		
		Items.GoodsRecipient.Visible = False;
		Items.GoodsRecipientBankAccount.Visible = False;
		Items.DeliveryAddress.Visible = False;
		Items.PowerOfAttorneyNumber.Visible = False;
		Items.PowerOfAttorneyDate.Visible = False;
		Items.LetterOfAuthorityIssuedBy.Visible = False;
		Items.PowerOfAttorneyPerson.Visible = False;
		Items.Shipper.Visible = False;
		Items.ShipperBankAccount.Visible = False;
		Items.IssuiedBy.Visible = False;
		Items.IssuiedByJobTitle.Visible = False;
	EndIf;
	
	If ObjectType = "CustomerInvoice"
		Or ObjectType = "GoodsShipmentToCustomer" Then
		FillInSelectionListOfTransportationAndCargoInformation();
		FillInSelectionListOfAccompanyingDocuments();
	Else
		Items.InformationOnTransportationAndCargo.Visible = False;
		Items.SupportingDocuments.Visible = False;
	EndIf;
	Items.DeliveryGroup.Visible = Items.DeliveryAddress.Visible Or ObjectType = "CustomerInvoice";
	
	FillSelectionList();
	
	DeliveryIsRequired = Parameters.DeliveryIsRequired;
	DeliverySpecificationMethod = Parameters.DeliverySpecificationMethod;
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		
		If DeliveryIsRequired
			And DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ForWholeDocument Then
			
			ToolTipText = NStr("ru = 'Адрес указан по точке доставки';
								|vi = 'Address is specified by delivery point';
								|en = 'Address is specified by delivery point'; fa = 'Address is specified by delivery point';
								|it = 'Address is specified by delivery point';
								|pl = 'Address is specified by delivery point';
								|tr = 'Adres teslimat noktasına göre belirtilmiş'");
			
			Items.DeliveryAddress.ReadOnly = True;
			Items.DeliveryAddress.ToolTip = ToolTipText;
			Items.DeliveryAddress.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
			
		ElsIf ReFillInDeliveryAddress Then
			
			GoodsDelivery.FillInListsForSelectingRecipientSenderAddresses(Items, DeliveryOrderData, True);
			
		Else
			
			FillInDeliveryAddressSelectionList();
			
		EndIf;
		
	Else
		
		If ReFillInDeliveryAddress Then
			GoodsDelivery.WhenReadingCreatingOrdersOnServer(
				Items,
				DeliveryOrderData,
				OrderSales Or SalesViaCommissionAgent,,,
				True);
		Else
			
			FillInDeliveryAddressSelectionList();
			
		EndIf;
		
	EndIf;
	
	SalesServerLocalization.WhenCreatingAtServerAttributesOfPrintingImplementation(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ForcefullyCloseTheForm Then
		Return;
	EndIf;
	
	If Modified And Not SaveParameters And Not Exit Then
		
		ButtonsList = New ValueList();
		ButtonsList.Add("Close", NStr("vi = 'Đóng';
										|ru = 'Закрыть';
										|en = 'Close'; fa = 'بستن';
										|it = 'Chiudere';
										|pl = 'Zamknij';
										|tr = 'Kapat'"));
		ButtonsList.Add("NotClose", NStr("vi = 'Không đóng';
										|ru = 'Не закрывать';
										|en = 'Do not close'; fa = 'بسته نشود';
										|it = 'Non chiudere';
										|pl = 'Nie zamykaj';
										|tr = 'Kapatmayın'"));
		
		ShowQueryBox(
			New CallbackDescription("BeforeClosingQuestionEnds", ThisObject),
			NStr("vi = 'Đã thay đổi chi tiết về bản in bán hàng hóa và dịch vụ. Đóng mà không lưu chi tiết?';
				|ru = 'Реквизиты печати реализации товаров и услуг были изменены. Закрыть без сохранения реквизитов?';
				|en = 'Print details  for customer invoice were changed. Close the form without saving the print details?'; fa = 'Print details  for customer invoice were changed. Close the form without saving the print details?';
				|it = 'I requisiti di stampa della vendita di merci e servizi sono stati modificati. Chiudere senza salvare i requisiti?';
				|pl = 'Szczegóły druk sprzedaży towarów i usług został zmieniony. Zamknij bez zapisywania szczegółów?';
				|tr = 'Ürün hizmet satışlarında yazdırma şartları değiştirilmiştir. Öznitelikleri kaydedilmeden kapat?'"),
			ButtonsList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClosingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = "NotClose" Then
		SaveParameters = False;
	ElsIf UserAnswer = "Close" Then
		ForcefullyCloseTheForm = True;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	If SaveParameters Then
		
		ParametersStructure = AttributesToChange(ThisForm);
		NotifyChoice(ParametersStructure);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BasisOnChange(Item)
	
	If ValueIsFilled(BasisObject) Then
		BasisChanged = (TrimAll(Basis) <> TrimAll(BasisObject));
	Else
		BasisChanged = False;
	EndIf;
	BasisObject = Basis;
	
	SelectedBases = PrintBasisTable.FindRows(New Structure("Basis", TrimAll(Basis)));
	If SelectedBases.Count() > 0 Then
		SelectedBase = SelectedBases.Get(0);
		BaseDocumentNumber = SelectedBase.BaseDocumentNumber;
		ReferenceDocumentDateForPrintForms  = SelectedBase.ReferenceDocumentDateForPrintForms;
	EndIf;
	
EndProcedure

&AtClient
Procedure BaseDocumentNumberOnChange(Item)
	If ValueIsFilled(ObjectBasisNumber)Then
		BasisChanged = (TrimAll(BaseDocumentNumber) <> TrimAll(ObjectBasisNumber));
	Else
		BasisChanged = False;
	EndIf;
	ObjectBasisNumber = BaseDocumentNumber;
EndProcedure

&AtClient
Procedure ReferenceDocumentDateForPrintFormsOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	If ValueIsFilled(ObjectBasisDate) Then
		BasisChanged = (TrimAll(ReferenceDocumentDateForPrintForms) <> TrimAll(ObjectBasisDate));
	Else
		BasisChanged = False;
	EndIf;
	ObjectBasisDate = ReferenceDocumentDateForPrintForms;
EndProcedure

&AtClient
Procedure ShipperOnChange(Item)
	
	If ValueIsFilled(Shipper) Then
		ShipperBankAccount = GetDefaultCounterpartyBankAccountServer(Shipper);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsRecipientOnChange(Item)
	
	If ValueIsFilled(GoodsRecipient) Or ReFillInDeliveryAddress Then
		GoodsRecipientOnChangeServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure DeliveryAddressOnChange(Item)
	
	If IsBlankString(DeliveryAddress) Then
		GoodsDeliveryClient.ClearAddressPresentation(DeliveryAddress, DeliveryAddressFieldValues, DeliveryAddressValue);
	Else
		GoodsDeliveryClient.WhenChangingAddressPresentation(Item, DeliveryAddress, DeliveryAddressValue);
		ConvertAddressToFreeForm();
	EndIf;
	
EndProcedure

&AtClient
Procedure DeliveryAddressChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	GoodsDeliveryClient.DeliveryAddressChoiceProcessing(Items, ThisObject, Item.Name, ValueSelected);
	Modified = True;
	
EndProcedure

&AtClient
Procedure PresentationOfCodeOfSpecialCircumstancesStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure PresentationOfCodeOfSpecialCircumstancesClearing(Item, StandardProcessing)
	
	Return;
	
EndProcedure

&AtClient
Procedure PresentationOfCodeOfSpecialCircumstancesOpening(Item, StandardProcessing)
	
	Return;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If Not ReadOnly Then
		SaveParameters = True;
	EndIf;
	
	Close();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClientAtServerNoContext
Function AttributesToChange(Source)
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("DeliveryAddress",                  Source.DeliveryAddress);
	ParametersStructure.Insert("DeliveryAddressValue",          Source.DeliveryAddressValue);
	ParametersStructure.Insert("DeliveryAddressFieldValues",     Source.DeliveryAddressFieldValues);
	ParametersStructure.Insert("DeliveryZone",                   Source.DeliveryZone);
	ParametersStructure.Insert("DeliveryTimeFrom",                 Source.DeliveryTimeFrom);
	ParametersStructure.Insert("DeliveryTimeTo",                Source.DeliveryTimeTo);
	ParametersStructure.Insert("AdditionalDeliveryInformation", Source.AdditionalDeliveryInformation);
	ParametersStructure.Insert("ShipperBankAccount", Source.ShipperBankAccount);
	ParametersStructure.Insert("GoodsRecipientBankAccount",  Source.GoodsRecipientBankAccount);
	ParametersStructure.Insert("CounterpartyBankAccount",      Source.CounterpartyBankAccount);
	ParametersStructure.Insert("RecipientCompanyBankAccount", Source.RecipientCompanyBankAccount);
	ParametersStructure.Insert("Shipper",               Source.Shipper);
	ParametersStructure.Insert("GoodsRecipient",                Source.GoodsRecipient);
	ParametersStructure.Insert("LetterOfAuthorityIssuedBy",             Source.LetterOfAuthorityIssuedBy);
	ParametersStructure.Insert("PowerOfAttorneyDate",               Source.PowerOfAttorneyDate);
	ParametersStructure.Insert("PowerOfAttorneyPerson",               Source.PowerOfAttorneyPerson);
	ParametersStructure.Insert("PowerOfAttorneyNumber",              Source.PowerOfAttorneyNumber);
	ParametersStructure.Insert("Basis",                      Source.Basis);
	ParametersStructure.Insert("ReferenceDocumentDateForPrintForms",                  Source.ReferenceDocumentDateForPrintForms);
	ParametersStructure.Insert("BaseDocumentNumber",                 Source.BaseDocumentNumber);
	ParametersStructure.Insert("IssuiedBy",                       Source.IssuiedBy);
	ParametersStructure.Insert("IssuiedByJobTitle",              Source.IssuiedByJobTitle);
	ParametersStructure.Insert("Director",                   Source.Director);
	ParametersStructure.Insert("InformationOnTransportationAndCargo", Source.InformationOnTransportationAndCargo);
	ParametersStructure.Insert("SupportingDocuments",      Source.SupportingDocuments);
	ParametersStructure.Insert("ChiefAccountant",               Source.ChiefAccountant);
	ParametersStructure.Insert("CompanyBankAccount",      Source.CompanyBankAccount);
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Procedure GoodsRecipientOnChangeServer()
	
	If ValueIsFilled(GoodsRecipient) Then
		GoodsRecipientBankAccount = GetDefaultCounterpartyBankAccountServer(GoodsRecipient);
	EndIf;
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		
		If Not (DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ForWholeDocument
					And DeliveryIsRequired) Then
			
			GoodsDelivery.FillInListsForSelectingRecipientSenderAddresses(Items, ThisObject, True);
			If Items.DeliveryAddress.ChoiceList.Count() > 0 Then
			
				FirstStructureInList = Items.DeliveryAddress.ChoiceList[0].Value;
				DeliveryAddress = FirstStructureInList.DeliveryAddress;
				DeliveryAddressValue = FirstStructureInList.DeliveryAddressValue;
				DeliveryAddressFieldValues = FirstStructureInList.DeliveryAddressFieldValues;
				
			EndIf;
			
		EndIf;
		
	Else
	
		If ReFillInDeliveryAddress Then
			FillParameters = GoodsDelivery.ParametersForFillingInBankingDetails();
			FillParameters.ClearDeliveryDetails = False;
			FillParameters.SetDeliveryMethod = False;
			GoodsDelivery.FillInDeliveryDetails(Items, "GoodsRecipient", ThisObject, FillParameters);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetDefaultCounterpartyBankAccountServer(Counterparty)
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	
	Return CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	
EndFunction

&AtServer
Procedure FillSelectionList()
	
	For Each TableRow In PrintBasisTable Do 
		Items.Basis.ChoiceList.Add(TableRow.Basis);
		If ValueIsFilled(TableRow.BaseDocumentNumber) Then
			Items.BaseDocumentNumber.ChoiceList.Add(TableRow.BaseDocumentNumber);
		EndIf;
		If ValueIsFilled(TableRow.ReferenceDocumentDateForPrintForms) Then
			Items.ReferenceDocumentDateForPrintForms.ChoiceList.Add(TableRow.ReferenceDocumentDateForPrintForms,Format(TableRow.ReferenceDocumentDateForPrintForms,"DLF=D"));
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInSelectionListOfTransportationAndCargoInformation()
	
	Items.InformationOnTransportationAndCargo.ChoiceList.Clear();
	ListOfTransportationInformation = New Array;
	
	
	If GoodsDeliveryClientServer.UsedDelivery20()
		And AccessRight("Read", Metadata.Documents.InstructionForShippingAgent) Then
			
		Query = New Query;
		Query.Text =
		"SELECT
		|	InstructionForShippingAgent.Date,
		|	InstructionForShippingAgent.Number
		|FROM
		|	Document.InstructionForShippingAgent AS InstructionForShippingAgent
		|		INNER JOIN Document.InstructionForShippingAgent.Basis1 AS InstructionForShippingAgentBasis1
		|		ON InstructionForShippingAgent.Ref = InstructionForShippingAgentBasis1.Ref
		|WHERE
		|	InstructionForShippingAgent.Posted = TRUE
		|	AND InstructionForShippingAgentBasis1.Basis = &DocumentBasis
		|GROUP BY
		|	InstructionForShippingAgent.Date,
		|	InstructionForShippingAgent.Number";
		
		Query.SetParameter("DocumentBasis", Ref);
		
		Selection = Query.Execute().Select();
		
		InstructionForShippingAgent  = NStr("vi = 'Giao hàng cho bên vận chuyển';
											|ru = 'Поручение экспедитору';
											|en = 'Delivery request'; fa = 'درخواست تحویل';
											|it = 'Поручение экспедитору';
											|pl = 'Zamówienie na transport';
											|tr = 'Teslimat talebi'");
		While Selection.Next() Do
			Invoice_Header = New Structure("Date, Number");
			FillPropertyValues(Invoice_Header, Selection);
			PresentationOfDeliveryRequestToFreightForwarder =
				TMCommonUseClientServer.GenerateDocumentTitle(Invoice_Header, InstructionForShippingAgent);
			ListOfTransportationInformation.Add(PresentationOfDeliveryRequestToFreightForwarder);
		EndDo;
	
	EndIf;
	
	If ValueIsFilled(ListOfTransportationInformation) Then
		Items.InformationOnTransportationAndCargo.ChoiceList.Add(StrConcat(ListOfTransportationInformation, ", "));
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInSelectionListOfAccompanyingDocuments()
	
	If GetFunctionalOption("UseQualityCertificates")
		And AccessRight("Read", Metadata.Catalogs.QualityCertificates) Then
		
		ObjectsArray = New Array;
		ObjectsArray.Add(Ref);
		
		QualityCertificates = Catalogs.QualityCertificates.DocumentNomenclatureCertificates(ObjectsArray);
		
		If ValueIsFilled(QualityCertificates) Then
			Items.SupportingDocuments.ChoiceList.Add(StrConcat(QualityCertificates, ", "));
		EndIf;
		
	EndIf;
	
EndProcedure


&AtServer
Procedure FillInDeliveryAddressSelectionList()
	
	DeliveryZone = Common.ObjectAttributeValue(Partner, "DeliveryZone");
	
	AddressOwners = CommonClientServer.ValueInArray(Partner);
	
	AddressesTable = ContactsManager.ObjectsContactInformation(
		AddressOwners,
		Enums.ContactInformationTypes.Address);
	
	AddressPresentationTemplate = NStr("vi = '%1: %2';
										|ru = '%1: %2';
										|en = '%1: %2'; fa = '%1: %2';
										|it = '%1: %2';
										|pl = '%1: %2';
										|tr = '%1: %2'");
	
	For Each AddressLine In AddressesTable Do
		
		AddressStructure1 = ChoiceStructure();
		AddressPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			AddressPresentationTemplate,
			String(AddressLine.Kind),
			AddressLine.Presentation);
		
		AddressStructure1.DeliveryAddress = AddressLine.Presentation;
		AddressStructure1.DeliveryAddressValue = AddressLine.Value;
		AddressStructure1.DeliveryAddressFieldValues = AddressLine.FieldValues;
		AddressStructure1.DeliveryZone = DeliveryZone;
		
		Items.DeliveryAddress.ChoiceList.Add(AddressStructure1, AddressPresentation);
		
	EndDo;
	
EndProcedure

// Returns:
//  Structure - Selection structure:
// * DeliveryAddress - String - 
// * DeliveryAddressValue - String - 
// * DeliveryAddressFieldValues - String - 
// * DeliveryZone - CatalogRef.DeliveryZones - 
//
&AtServerNoContext
Function ChoiceStructure()
	
	ChoiceStructure = New Structure;
	ChoiceStructure.Insert("DeliveryAddress", "");
	ChoiceStructure.Insert("DeliveryAddressValue", "");
	ChoiceStructure.Insert("DeliveryAddressFieldValues", "");
	ChoiceStructure.Insert("DeliveryZone", Catalogs.DeliveryZones.EmptyRef());
	
	Return ChoiceStructure;
	
EndFunction

&AtServer
Procedure ConvertAddressToFreeForm()
	
	AddressStructure1 = ContactsManager.InfoAboutAddress(DeliveryAddressValue);
	PresentationFromJson = ContactsManager.AddressPresentation(AddressStructure1);
	
	If StrCompare(DeliveryAddress, PresentationFromJson) <> 0 Then
		
		CountryData1 = ContactsManager.ContactInformationAddressCountry(DeliveryAddressValue);
		
		NewAddressStructure = ContactsManager.InfoAboutAddress();
		NewAddressStructure.Presentation = DeliveryAddress;
		NewAddressStructure.Country = CountryData1.Description;
		NewAddressStructure.CountryCode = CountryData1.Code;
		
		DeliveryAddressValue = ContactsManager.ContactInformationInJSON(
			NewAddressStructure,
			Enums.ContactInformationTypes.Address);
		
		SetAddressTypeInFreeForm(DeliveryAddressValue);
		
	EndIf;
	
	DeliveryAddressFieldValues = ContactsManager.ContactInformationToXML(
		DeliveryAddressValue,
		DeliveryAddress,
		Enums.ContactInformationTypes.Address);
	
EndProcedure

&AtServerNoContext
Procedure SetAddressTypeInFreeForm(DeliveryAddressValue)
	
	StringTypeToReplace = """addressType"": ""Administrative-territorial""";
	StringIsFreeType = """addressType"": ""FreeForm""";
	DeliveryAddressValue = StrReplace(DeliveryAddressValue, StringTypeToReplace, StringIsFreeType);
	
EndProcedure

#EndRegion

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
	If Item.Name = "sh_ShamsiInput_F_ReferenceDocumentDateForPrintForms" Then
		ReferenceDocumentDateForPrintFormsOnChange(Items.ReferenceDocumentDateForPrintForms);
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
