#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	DataExchangeServer.NodeFormOnCreateAtServer(ThisForm, Cancel);
	
	CreateListOfContractFormationRules();
	
	If Object.UseFilterByCompanies Then
		CatalogsFilterRule = "Filter";
	Else
		If Object.UnloadManagementCompany Then
			CatalogsFilterRule = "ManOrganization";
		Else
			CatalogsFilterRule = "NoFilter";
		EndIf;
	EndIf;
	
	If Object.UseFilterByAccountingSections Then
		ModeForUploadingAccountingSections = 1;
	ElsIf Object.AccountingSections.Count() = 0 Then
		Object.AccountingSections.Load(ExchangePlans.DataSynchronizationViaUniversalFormat.GetAccountingSections(
			False, Object.SettingsMode));
		ModeForUploadingAccountingSections = 0;
	EndIf;
	
	If Object.DocumentsKinds.Count() > 0 And Not Object.UseFilterByAccountingSectionAndDocument Then
	     Object.UseFilterByAccountingSectionAndDocument = True;
	EndIf;
		
	UseSeveralPriceTypes = GetFunctionalOption("UseSeveralPriceTypes");
	UseSeveralWarehouses  = GetFunctionalOption("UseSeveralWarehouses");
	
	If Object.SettingsMode = "CashExchange"
		And UseSeveralPriceTypes
		And Object.ProductPricesTypes.Count() > 0 Then
		PricesKind = Object.ProductPricesTypes[0].ProductPricesType;
	EndIf;
	
	If Object.SettingsMode = "ExchangeOfUPRMC" Then

		If Not GetFunctionalOption("UseRetailSales") Then

			Raise NStr("vi = 'Để tùy chỉnh trao đổi với ""1C:Cashier''s workplace"",
								   |cần bật tùy chọn chức năng ""Bán lẻ"".';
								   |ru = 'Для настройки обмена с ""1С:Рабочее место кассира"",
								   |требуется включить функциональную опцию ""Розничные продажи"".';
								   |en = 'To set up exchange with 1C:POS
								   |enable the ""Retail sales"" functional option.'; fa = 'To set up exchange with 1C:POS
								   |enable the ""Retail sales"" functional option.';
								   |it = 'Для настройки обмена с ""1С:Рабочее место кассира"",
								   |требуется включить функциональную опцию ""Розничные продажи"".';
								   |pl = 'To set up exchange with 1C:POS
								   |enable the ""Retail sales"" functional option.';
								   |tr = '""1C:POS"" ile değişimi ayarlamak için ""Perakende satışlar""
								   |fonksiyonel seçeneğini etkinleştirmeniz gerekmektedir.'");
		EndIf;
		
		Items.FilterAlignmentByIndividualsGroup.ExtendedTooltip.Title = 
			NStr("vi = 'Nên chỉ ra người bán và thu ngân của cơ sở bán hàng';
				|ru = 'Рекомендуется указывать продавцов и кассиров торгового объекта';
				|en = 'We recommended that you specify sellers and cashiers of the retail facility'; fa = 'We recommended that you specify sellers and cashiers of the retail facility';
				|it = 'Si consigli di indicare i venditori e i cassieri dell''oggetto commerciale';
				|pl = 'Zalecane jest określenie sprzedawców i kasjerów obiektu handlowego';
				|tr = 'Ticari nesnenin satış görevlilerinin ve kasiyerlerinin belirtilmesi önerilmektedir'");
		
		FormatVersionIsBelow117 = FormatVersionIsBelow(Object.ExchangeFormatVersion, "1.17");
		Items.FilterGroupByCashAccountQC.Visible = FormatVersionIsBelow117;
		Items.CashAccountSelectionGroupCashRegister.Visible = Not FormatVersionIsBelow117;
		
		If Object.CashRegisters.Count() > 0 Then
			CashRegister = Object.CashRegisters[0].CashRegister;
		EndIf;
	EndIf;
	
	// Initialize the availability of the installation links the date of the ban on editing and the date of the ban on receiving.
	ItemArray = New Array;
	ItemArray.Add("SetDateWhenDataCollectionIsProhibited");
	ItemArray.Add("SetPeriodEndClosingDate");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		ItemArray,
		"Enabled",
		AccessRight("Update", Metadata.InformationRegisters.PeriodClosingDates));  
		
	Items.CostAccountProductRelease.Mask = DataExchangeEventsTMERP.AccountMask();
	Items.CostAccountMaterialTransferToProduction.Mask = DataExchangeEventsTMERP.AccountMask();
	AutocompletionByDocumentType();
	SetVisibilityOnServer();
	UpdateListOfSelectedVersionsOfExchangeFormat();
	If StandardSubsystemsServer.IsBaseConfigurationVersion() And (Object.SentNo = 0) Then
	     Object.AllowDataImportToBaseVersion = True;
	EndIf;
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	Notify("Write_ExchangePlanNode");
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If CurrentObject.SettingsMode = "CashExchange"
		And ThisObject.UseSeveralPriceTypes Then
		
		CurrentObject.ProductPricesTypes.Clear();
		
		DifferentTypesOfPrices = CurrentObject.ProductPricesTypes.Add();
		DifferentTypesOfPrices.ProductPricesType = ThisObject.PricesKind;
	EndIf;
	
	If CurrentObject.SettingsMode = "ExchangeOfUPRMC" Then
		
		FormatVersionIsBelow117 = FormatVersionIsBelow(Object.ExchangeFormatVersion, "1.17");
		If FormatVersionIsBelow117 Then
				
			CurrentObject.CashRegisters.Clear();
			String = CurrentObject.CashRegisters.Add();
			String.CashRegister = ThisObject.CashRegister;
		
		EndIf;
		If CurrentObject.CashRegisters.Count() = 0 Then
			Cancel = True;
			Common.MessageToUser(NStr("vi = 'Cần chỉ ra quầy thu ngân';
										|ru = 'Нужно указать кассу ККМ';
										|en = 'Specify the cash register'; fa = 'Specify the cash register';
										|it = 'Нужно указать кассу ККМ';
										|pl = 'Specify the cash register';
										|tr = 'KKM''nin yazarkasasını belirtmek gerekir'"));
		EndIf;
		
		CurrentObject.UseFilterByCashRegisters = True;
		
	EndIf;
	
	If CurrentObject.DocumentsKinds.Count() = 0 Then
		CurrentObject.UseFilterByAccountingSectionAndDocument = False;
	ElsIf CurrentObject.UseFilterByAccountingSectionAndDocument = False Then    
		CurrentObject.DocumentsKinds.Clear();
	EndIf;
	If CurrentObject.UploadInformativeBalance And Not WorkIsExecutedViaSalesRepresentatives Then
		CurrentObject.UploadInformativeBalance = False;
	EndIf;
	SectionsArray = CurrentObject.AccountingSections.Unload(New Structure("ToExport", True)); 
	If (Constants.TradeManagement.Get()
		And SectionsArray.Count() < 5) Or SectionsArray.Count() < 7 Then
	    ModeForUploadingAccountingSections = 1;
	EndIf;
	
	CurrentObject.UseFilterByAccountingSections = Not CurrentObject.UseFilterByAccountingSectionAndDocument And ModeForUploadingAccountingSections = 1;
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	RefreshInterface();
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If TypeOf(ChoiceSource) = Type("ClientApplicationForm")
		And ChoiceSource.FormName = "CommonForm.FormOfMarkingOfItems" Then
		
		// Accounting sections are selected.
		For Each SectionRow In Object.AccountingSections Do
			
			SelectionValue  = ValueSelected.FindByValue(SectionRow.AccountingSection);
			
			If Not SelectionValue  = Undefined Then
				SectionRow.ToExport = SelectionValue.Check;
			EndIf;
			
		EndDo;
		
		UpdateNameOfFormCommands();
	Else
		UpdateObjectData(ValueSelected);
	EndIf;
	
	Modified = True;

	RefreshInterface();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If FormAgreements() And Not ValueIsFilled(Object.RulesForCreatingCounterpartyContracts) Then
		Common.MessageToUser(
			NStr("vi = 'Cần điền quy tắc tạo hợp đồng.';
				|ru = 'Необходимо заполнить правила формирования договоров.';
				|en = 'Fill in contract generation rules.'; fa = 'Fill in contract generation rules.';
				|it = 'È necessario compilare le regole di creazione dei contratti.';
				|pl = 'Należy wypełnić reguły generowania kontraktów.';
				|tr = 'Sözleşme oluşturma kurallarını doldurmak gerekir.'"), ,
			"Object.RulesForCreatingCounterpartyContracts");
		Cancel = True;
	EndIf;
	
	If Object.SettingsMode = "CashExchange" And ThisObject.UseSeveralPriceTypes
		And Not ValueIsFilled(ThisObject.PricesKind) Then
		
		Common.MessageToUser(
			NStr("vi = 'Cần điền dạng giá.';
				|ru = 'Необходимо заполнить вид цен.';
				|en = 'Fill in a price type.'; fa = 'Fill in a price type.';
				|it = 'È necessario compilare il tipo di prezzo.';
				|pl = 'Należy wypełnić rodzaj cen.';
				|tr = 'Fiyat türünün doldurulması gerekir.'"), ,
			"PricesKind");
		Cancel = True;
	EndIf;
	
	If Object.SettingsMode = "ExchangeOfUPRMC" 
		And Object.CashRegisters.Count() = 0 Then
		
		Cancel = True;
		
		MessageToUserText = NStr("vi = 'Cần điền quầy thu ngân.';
								|ru = 'Необходимо заполнить кассу ККМ.';
								|en = 'Fill the cash register.'; fa = 'Fill the cash register.';
								|it = 'Необходимо заполнить кассу ККМ.';
								|pl = 'Należy wypełnić kasę fiskalną.';
								|tr = 'YK doldurulması gerekir.'");
		If FormatVersionIsBelow(Object.ExchangeFormatVersion, "1.17") Then
			Common.MessageToUser(MessageToUserText, , Items.CashRegisterCashierField.DataPath);
		Else
			Common.MessageToUser(MessageToUserText, , , Items.SpecifyListOfCashRegisterCashAccountsButton.Name);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	DataExchangeClient.SetupFormBeforeClose(Cancel, ThisObject, Exit);
	
EndProcedure

&AtClient
Procedure Attachable_URLProcessing(Item, Var_URL, StandardProcessing)
	
	DataExchangeClient.HandleURLInNodeForm(ThisObject, Item, Var_URL, StandardProcessing);
		
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	DataExchangeServer.NodeFormOnWriteAtServer(CurrentObject, Cancel);
		
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ConstantsSet" 
		And Source = "WorkIsExecutedViaSalesRepresentatives" Then 
		
		SetVisibilityOnServer();
		
	EndIf;
		
EndProcedure

#EndRegion
#Region FormHeaderItemsEventHandlers
&AtClient
Procedure FlagUseFilterByCompaniesOnChange(Item)
	SetVisibilityOnServer();
EndProcedure

&AtClient
Procedure SendInfoFlag(Item)
	SetVisibilityOnServer();
EndProcedure

&AtClient
Procedure SendMasterDataAutomaticallyRadioButtonsOnChange(Item)
	SetVisibilityOnServer();
EndProcedure

&AtClient
Procedure SendMasterDataAsNecessaryRadioButtonsOnChange(Item)
	SetVisibilityOnServer();
EndProcedure

&AtClient
Procedure NeverSendMasterDataRadioButtonsOnChange(Item)
	Object.DocumentsSendingRules = "NotSynchronize";
	SetVisibilityOnServer();
EndProcedure

&AtClient
Procedure CatalogSelectionSwitchWithSelectionOnChange(Item)
	SetSynchronizationRestrictionConditions();
	SetVisibilityOnServer();
EndProcedure

&AtClient
Procedure CatalogSelectionSwitchWithoutManSelectionOnChange(Item)
	SetSynchronizationRestrictionConditions();
	SetVisibilityOnServer();
EndProcedure

&AtClient
Procedure CatalogSelectionSwitchWithoutSelectionWithoutManOnChange(Item)
	SetSynchronizationRestrictionConditions();
	SetVisibilityOnServer();
EndProcedure

&AtClient
Procedure ModeSwitchForUnloadingAccountingSectionsWithoutSelectionOnChange(Item)
	SetSynchronizationRestrictionConditions();   
	SetVisibilityOnServer(); 
EndProcedure

&AtClient
Procedure ModeSwitchForUnloadingAccountingSectionsWithSelectionOnChange(Item)
	SetSynchronizationRestrictionConditions();
	SetVisibilityOnServer();
EndProcedure

&AtClient
Procedure DocumentUploadModeOnChange(Item)
	SetSynchronizationRestrictionConditions();
	If Object.UseFilterByAccountingSections Then
		ModeForUploadingAccountingSections = 1; 
	Else
		Object.DocumentsKinds.Clear();
	EndIf;

	SetVisibilityOnServer();
EndProcedure

&AtClient
Procedure SendDocumentsAutomaticallyRadioButtonsOnChange(Item)
	SetVisibilityOnServer();
EndProcedure

&AtClient
Procedure SendDocumentsManuallyRadioButtonsOnChange(Item)
	SetVisibilityOnServer();
EndProcedure

&AtClient
Procedure DoNotSendDocumentsRadioButtonOnChange(Item)
	SetVisibilityOnServer();
EndProcedure

&AtClient
Procedure ProductPriceTypesFlag(Item)
	SetVisibilityOnServer();
	If Object.UploadProductPrices Then
		OpenFormForSelectingAdditionalConditionsForPriceTypes(); 
	EndIf;
EndProcedure

&AtClient
Procedure UseCourierSelectionOnChange(Item)
	SetVisibilityOnServer();
EndProcedure

&AtClient
Procedure UseWarehouseSelectionOnChange(Item)
	SetVisibilityOnServer();
EndProcedure

&AtClient
Procedure UseFilterByPersonsOnChange(Item)
	SetVisibilityOnServer();
EndProcedure

&AtClient
Procedure UseFilterByPOSTerminalsOnChange(Item)
	SetVisibilityOnServer();
EndProcedure

&AtClient
Procedure CashRegisterCashierFieldOnChange(Item)
	
	UpdateDependentSelections();
	UpdateNameOfFormCommands();
	Modified = True;
	
EndProcedure

&AtClient
Procedure ClearSelectionByDocumentType(Command)
	TitleText = NStr("vi = 'Xác nhận';
					|ru = 'Подтверждение';
					|en = 'Confirmation'; fa = 'تأیید';
					|it = 'Подтверждение';
					|pl = 'Confirmation';
					|tr = 'Onay'");
	QueryText   = NStr("vi = 'Xóa bộ lọc theo dạng chứng từ?';
						|ru = 'Очистить отбор по видам документов?';
						|en = 'Do you want to clear the filter by document kind?'; fa = 'Do you want to clear the filter by document kind?';
						|it = 'Очистить отбор по видам документов?';
						|pl = 'Do you want to clear the filter by document kind?';
						|tr = 'Belge türüne göre filtreyi temizle?'");
	
	ShowQueryBox(New CallbackDescription("ClearSelectionByDocumentTypeCompletion", ThisObject), QueryText,
	QuestionDialogMode.YesNo, , , TitleText);
EndProcedure

&AtClient
Procedure ClearSelectionByDocumentTypeCompletion(Result, AdditionalParameters) Export
	
	Response = Result;
	If Response = DialogReturnCode.Yes Then
		Object.DocumentsKinds.Clear(); 
		Object.UseFilterByAccountingSectionAndDocument = False;
		SetVisibilityOnServer();
		UpdateNameOfFormCommands();
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure UseFilterByPaymentSystemContractsOnChange(Item)
	SetVisibilityOnServer();
EndProcedure

&AtClient
Procedure UseFilterByCashRegistersOnChange(Item)
	
	SetVisibilityOnServer();
	
EndProcedure

&AtClient
Procedure FlagForSendingInformativeBalancesExtendedTooltipURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	URLProcessing(FormattedStringURL);
	
EndProcedure

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure OpenSelectedCompaniesList(Command)
	
	If Not Object.UnloadManagementCompany
		Or Not GetInterfaceFunctionalOption("UseManagementCompany") Then
		
		FilterCollection = New Array;
		
		SuperimposedFilters = New Structure();
		SuperimposedFilters.Insert("AttributeOfFilter",    "Ref");
		SuperimposedFilters.Insert("Condition",           "<>");
		SuperimposedFilters.Insert("ParameterName",      "ExcludedLink");
		SuperimposedFilters.Insert("ParameterValue", 
			CommonClient.PredefinedItem("Catalog.Companies.ManagementCompany"));
		
		FilterCollection.Add(SuperimposedFilters);
		
	Else
		
		FilterCollection = Undefined;
		
	EndIf;
	
	FormParameters = New Structure();
	FormParameters.Insert("NameOfFormElementToFillIn",          "Companies");
	FormParameters.Insert("NameOfFormElementDetailsToFillIn", "Organization");
	FormParameters.Insert("NameOfSelectionTable",                       "Catalog.Companies");
	FormParameters.Insert("SelectionFormHeader",                   NStr("vi = 'Chọn doanh nghiệp để lọc:';
																		|ru = 'Выберите организации для отбора:';
																		|en = 'Select companies to filter:'; fa = 'Select companies to filter:';
																		|it = 'Selezionare azienda per filtro:';
																		|pl = 'Wybierz firmy do filtrowania:';
																		|tr = 'Filtre için iş yerini seç:'"));
	FormParameters.Insert("ArrayOfSelectedValues_",                GenerateArrayOfSelectedValues(FormParameters));
	FormParameters.Insert("ExternalConnectionParameters",            Undefined);
	FormParameters.Insert("FilterCollection",                      FilterCollection);
	FormParameters.Insert("ProhibitionOfChangingListValues",          True);
	
	OpenForm("CommonForm.AdditionalConditionsSelectionForm",
		FormParameters,
		ThisForm);
	
EndProcedure

&AtClient
Procedure OpenListOfProductPriceTypesToSend(Command) 
	OpenFormForSelectingAdditionalConditionsForPriceTypes();
EndProcedure 

&AtClient
Procedure OpenFormForSelectingAdditionalConditionsForPriceTypes()
	FormParameters = New Structure();
	FormParameters.Insert("NameOfFormElementToFillIn",          "ProductPricesTypes");
	FormParameters.Insert("NameOfFormElementDetailsToFillIn", "ProductPricesType");
	FormParameters.Insert("NameOfSelectionTable",                       "Catalog.TypesOfPrices");
	FormParameters.Insert("SelectionFormHeader",                   NStr("vi = 'Chọn dạng giá để gửi:';
																		|ru = 'Выберите виды цен для отправки:';
																		|en = 'Select price types for sending:'; fa = 'Select price types for sending:';
																		|it = 'Выберите виды цен для отправки:';
																		|pl = 'Wybierz rodzaje cena do wysyłki:';
																		|tr = 'Gönderim için fiyat türünü seç:'"));
	FormParameters.Insert("ArrayOfSelectedValues_",                GenerateArrayOfSelectedValues(FormParameters));
	FormParameters.Insert("ExternalConnectionParameters",            Undefined);
	FormParameters.Insert("FilterCollection",                      Undefined);
	
	OpenForm("CommonForm.AdditionalConditionsSelectionForm",
		FormParameters,
		ThisForm);
EndProcedure

&AtClient
Procedure OpenListOfSentWarehousesInformLeftovers(Command)
	
	FormParameters = New Structure();
	FormParameters.Insert("NameOfFormElementToFillIn",          "WarehousesOfInformativeBalance");
	FormParameters.Insert("NameOfFormElementDetailsToFillIn", "Warehouse");
	FormParameters.Insert("NameOfSelectionTable",                       "Catalog.Warehouses");
	FormParameters.Insert("SelectionFormHeader",                   NStr("vi = 'Chọn kho cần kết xuất thông tin số dư:';
																		|ru = 'Выберите склады, для которых требуется выгрузить информативные остатки:';
																		|en = 'Select the warehouses for which you need to export stock balance information:'; fa = 'Select the warehouses for which you need to export stock balance information:';
																		|it = 'Selezionare magazzini per i quali è richiesto l''upload dei saldi informativi:';
																		|pl = 'Wybierz magazyny, dla których należy wyeksportować salda informatyczne:';
																		|tr = 'Bilgilendirici bakiyeleri yüklemek için istediğiniz ambarları seç:'"));
	FormParameters.Insert("ArrayOfSelectedValues_",                GenerateArrayOfSelectedValues(FormParameters));
	FormParameters.Insert("ExternalConnectionParameters",            Undefined);
	FormParameters.Insert("FilterCollection",                      Undefined);
	
	OpenForm("CommonForm.AdditionalConditionsSelectionForm",
		FormParameters,
		ThisForm);
	
EndProcedure

&AtClient
Procedure OpenListOfSelectedAccountingSections(Command)
	
	ListOfAccountingSections = New ValueList;
	For Each SectionRow In Object.AccountingSections Do
		ListOfAccountingSections.Add(SectionRow.AccountingSection, , SectionRow.ToExport);
	EndDo;
	
	OpenForm("CommonForm.FormOfMarkingOfItems",New Structure("ValueList", ListOfAccountingSections),ThisObject);

EndProcedure

&AtClient
Procedure OpenListOfDepotsToSend(Command)
	
	FormParameters = New Structure();
	FormParameters.Insert("NameOfFormElementToFillIn",          "Warehouses");
	FormParameters.Insert("NameOfFormElementDetailsToFillIn", "Warehouse");
	FormParameters.Insert("NameOfSelectionTable",                       "Catalog.Warehouses");
	FormParameters.Insert("SelectionFormHeader",                   NStr("vi = 'Hãy chọn kho';
																		|ru = 'Выберите склады';
																		|en = 'Select warehouses'; fa = 'انتخاب انبارها';
																		|it = 'Selezionare magazzini';
																		|pl = 'Wybierz magazyny';
																		|tr = 'Ambarları seç'"));
	FormParameters.Insert("ArrayOfSelectedValues_",                GenerateArrayOfSelectedValues(FormParameters));
	FormParameters.Insert("ExternalConnectionParameters",            Undefined);
	FormParameters.Insert("FilterCollection",                      Undefined);
	
	OpenForm("CommonForm.AdditionalConditionsSelectionForm",
		FormParameters,
		ThisForm);
	
EndProcedure

&AtClient
Procedure OpenListOfCouriers(Command)
	
	FormParameters = New Structure();
	FormParameters.Insert("NameOfFormElementToFillIn",          "Couriers");
	FormParameters.Insert("NameOfFormElementDetailsToFillIn", "Courier");
	FormParameters.Insert("NameOfSelectionTable",                       "Catalog.Persons");
	FormParameters.Insert("SelectionFormHeader",                   NStr("vi = 'Chọn bên chuyển phát';
																		|ru = 'Выберите курьеров';
																		|en = 'Select couriers'; fa = 'انتخاب پیک‌ها';
																		|it = 'Selezionare corrieri';
																		|pl = 'Wybierz kurierów';
																		|tr = 'Kuryeleri seç'"));
	FormParameters.Insert("ArrayOfSelectedValues_",                GenerateArrayOfSelectedValues(FormParameters));
	FormParameters.Insert("ExternalConnectionParameters",            Undefined);
	FormParameters.Insert("FilterCollection",                      Undefined);
	
	OpenForm("CommonForm.AdditionalConditionsSelectionForm",
		FormParameters,
		ThisForm);
	
EndProcedure

&AtClient
Procedure OpenListOfIndividuals(Command)
	
	FormParameters = New Structure();
	FormParameters.Insert("NameOfFormElementToFillIn",          "Persons");
	FormParameters.Insert("NameOfFormElementDetailsToFillIn", "Individual");
	FormParameters.Insert("NameOfSelectionTable",                       "Catalog.Persons");
	FormParameters.Insert("SelectionFormHeader",                   NStr("vi = 'Hãy chọn cá nhân';
																		|ru = 'Выберите физические лица';
																		|en = 'Select persons'; fa = 'انتخاب اشخاص';
																		|it = 'Selezionare persone fisiche';
																		|pl = 'Wybierz osób fizycznych';
																		|tr = 'Gerçek kişileri seç'"));
	FormParameters.Insert("ArrayOfSelectedValues_",                GenerateArrayOfSelectedValues(FormParameters));
	FormParameters.Insert("ExternalConnectionParameters",            Undefined);
	FormParameters.Insert("FilterCollection",                      Undefined);
	
	OpenForm("CommonForm.AdditionalConditionsSelectionForm",
		FormParameters,
		ThisForm);
	
EndProcedure

&AtClient
Procedure OpenListOfAcquiringTerminalsToSend(Command)
	
	If Object.UseFilterByCompanies  Then
		
		FilterCollection = New Array;
		
		SuperimposedFilters = New Structure();
		
		ParametersForSelectingValues = New Structure();
		
		ParametersForSelectingValues.Insert("NameOfFormElementToFillIn",          "Companies");
		ParametersForSelectingValues.Insert("NameOfFormElementDetailsToFillIn", "Organization");
		
		SuperimposedFilters.Insert("AttributeOfFilter",    "Owner.Organization");
		SuperimposedFilters.Insert("Condition",           "In");
		SuperimposedFilters.Insert("ParameterName",      "Companies");
		SuperimposedFilters.Insert("ParameterValue",  GenerateArrayOfSelectedValues(ParametersForSelectingValues)); 
		
		FilterCollection.Add(SuperimposedFilters);
		
	Else
		
		FilterCollection = Undefined;
		
	EndIf;
	
	FormParameters = New Structure();
	
	FormParameters.Insert("NameOfFormElementToFillIn",          "POSTerminals");
	FormParameters.Insert("NameOfFormElementDetailsToFillIn", "POSTerminal");
	FormParameters.Insert("NameOfSelectionTable",                       "Catalog.POSTerminals");
	FormParameters.Insert("SelectionFormHeader",                   NStr("vi = 'Hãy chọn thiết thị thanh toán thẻ';
																		|ru = 'Выберите эквайринговые терминалы';
																		|en = 'Select POS terminals'; fa = 'انتخاب پایانه‌های POS';
																		|it = 'Selezionare terminali di acquisizione';
																		|pl = 'Wybierz terminale płatnicze';
																		|tr = 'PoS terminallerini seç'"));
	FormParameters.Insert("ArrayOfSelectedValues_",                GenerateArrayOfSelectedValues(FormParameters));
	FormParameters.Insert("ExternalConnectionParameters",            Undefined);
	FormParameters.Insert("FilterCollection",                      FilterCollection);
	
	OpenForm("CommonForm.AdditionalConditionsSelectionForm",
		FormParameters,
		ThisForm);
	
EndProcedure

&AtClient
Procedure OpenListOfCashRegisterCashiersToBeSent(Command)
	
	If Object.UseFilterByCompanies  Then
		
		FilterCollection = New Array;
		
		SuperimposedFilters = New Structure();
		
		ParametersForSelectingValues = New Structure();
		
		ParametersForSelectingValues.Insert("NameOfFormElementToFillIn",          "Companies");
		ParametersForSelectingValues.Insert("NameOfFormElementDetailsToFillIn", "Organization");
		
		SuperimposedFilters.Insert("AttributeOfFilter",    "Owner");
		SuperimposedFilters.Insert("Condition",           "In");
		SuperimposedFilters.Insert("ParameterName",      "Companies");
		SuperimposedFilters.Insert("ParameterValue",  GenerateArrayOfSelectedValues(ParametersForSelectingValues)); 
		
		FilterCollection.Add(SuperimposedFilters);
		
	Else
		
		FilterCollection = Undefined;
		
	EndIf;
	
	FormParameters = New Structure();
	
	FormParameters.Insert("NameOfFormElementToFillIn",          "CashRegisters");
	FormParameters.Insert("NameOfFormElementDetailsToFillIn", "CashRegister");
	FormParameters.Insert("NameOfSelectionTable",                       "Catalog.CashRegisters");
	FormParameters.Insert("SelectionFormHeader",                   NStr("vi = 'Hãy chọn quầy thu ngân';
																		|ru = 'Выберите кассы ККМ';
																		|en = 'Select cash registers'; fa = 'انتخاب صندوق‌های فروش';
																		|it = 'Выберите кассы ККМ';
																		|pl = 'Select cash registers';
																		|tr = 'Yazar kasaları seçin'"));
	FormParameters.Insert("ArrayOfSelectedValues_",                GenerateArrayOfSelectedValues(FormParameters));
	FormParameters.Insert("ExternalConnectionParameters",            Undefined);
	FormParameters.Insert("FilterCollection",                      FilterCollection);
	
	OpenForm("CommonForm.AdditionalConditionsSelectionForm",
		FormParameters,
		ThisObject);
	
EndProcedure

&AtClient
Procedure OpenListOfCashRegisterCashAccountsToBeSentWithoutSelectionByCompany(Command)
	FormParameters = New Structure();
	
	FormParameters.Insert("NameOfFormElementToFillIn",          "CashRegisters");
	FormParameters.Insert("NameOfFormElementDetailsToFillIn", "CashRegister");
	FormParameters.Insert("NameOfSelectionTable",                       "Catalog.CashRegisters");
	FormParameters.Insert("SelectionFormHeader",                   
							NStr("vi = 'Hãy chọn quầy thu ngân.';
								|ru = 'Выберите кассы ККМ.';
								|en = 'Select cash registers.'; fa = 'Select cash registers.';
								|it = 'Выберите кассы ККМ.';
								|pl = 'Select cash registers.';
								|tr = 'Yazar kasaları seçin.'"));
	FormParameters.Insert("ArrayOfSelectedValues_",                GenerateArrayOfSelectedValues(FormParameters));
	FormParameters.Insert("ExternalConnectionParameters",            Undefined);
	FormParameters.Insert("FilterCollection",                      Undefined);
	FormParameters.Insert("SpecialConditions",                      	  New Structure("TheseAreCashRegisterCashAccountsForCWP", True));
	
	OpenForm("CommonForm.AdditionalConditionsSelectionForm", FormParameters, ThisObject);
EndProcedure

&AtClient
Procedure OpenListOfAcquisitionContractsToBeSent(Command)
	
	If Not Object.UseFilterByCompanies  Then
		
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền bộ lọc theo doanh nghiệp.';
										|ru = 'Не заполнен фильтр по организациям.';
										|en = 'Filter by companies is required.'; fa = 'Filter by companies is required.';
										|it = 'Не заполнен фильтр по организациям.';
										|pl = 'Filter by companies is required.';
										|tr = 'İş yeri filtresi doldurulmadı.'"),, "Object.UseFilterByCompanies");
		
		Return;
		
	EndIf;
	
	FilterCollection = New Array;
	
	SuperimposedFilters = New Structure();
	
	ParametersForSelectingValues = New Structure();
	
	ParametersForSelectingValues.Insert("NameOfFormElementToFillIn",          "Companies");
	ParametersForSelectingValues.Insert("NameOfFormElementDetailsToFillIn", "Organization");
	
	SuperimposedFilters.Insert("AttributeOfFilter",    "Organization");
	SuperimposedFilters.Insert("Condition",           "In");
	SuperimposedFilters.Insert("ParameterName",      "Companies");
	SuperimposedFilters.Insert("ParameterValue",  GenerateArrayOfSelectedValues(ParametersForSelectingValues)); 
	
	FilterCollection.Add(SuperimposedFilters);

	SuperimposedFilters = New Structure();
	SuperimposedFilters.Insert("AttributeOfFilter",    "MakingPaymentMethod");
	SuperimposedFilters.Insert("Condition",           "=");
	SuperimposedFilters.Insert("ParameterName",      "MakingPaymentMethod");
	SuperimposedFilters.Insert("ParameterValue",	
		PredefinedValue("Enum.MakingPaymentMethods.InstantPayments")); 

	FilterCollection.Add(SuperimposedFilters);
	
	FormParameters = New Structure();
	FormParameters.Insert("NameOfFormElementToFillIn",          "PaymentSystemContracts");
	FormParameters.Insert("NameOfFormElementDetailsToFillIn", "ConnectionContract");
	FormParameters.Insert("NameOfSelectionTable",                       "Catalog.AcquiringContracts");
	FormParameters.Insert("SelectionFormHeader",                   NStr("vi = 'Hãy chọn hợp đồng kết nối (đến hệ thống thanh toán)';
																		|ru = 'Выберите договоры подключения (к платежным системам)';
																		|en = 'Select payment system contracts'; fa = 'انتخاب قراردادهای سیستم پرداخت';
																		|it = 'Выберите договоры подключения (к платежным системам)';
																		|pl = 'Select payment system contracts';
																		|tr = 'Bağlantı sözleşmeleri seçin (ödeme sistemlerine)'"));
	FormParameters.Insert("ArrayOfSelectedValues_",                GenerateArrayOfSelectedValues(FormParameters));
	FormParameters.Insert("ExternalConnectionParameters",            Undefined);
	FormParameters.Insert("FilterCollection",                      FilterCollection);
	
	OpenForm("CommonForm.AdditionalConditionsSelectionForm",
		FormParameters,
		ThisForm);
	
EndProcedure

&AtClient
Procedure DocumentSelectionFormClick(Item)
	FormParameters = New Structure();
	FormParameters.Insert("DocumentsKinds", ArrayOfSettingsTableObjects("DocumentsKinds", "MetadataObjectName"));
	
	OpenForm("ExchangePlan.DataSynchronizationViaUniversalFormat.Form.FormToSelectDocumentKinds",
		FormParameters, ThisObject);

EndProcedure 

#EndRegion
#Region Private

#Region Other

&AtServer
Procedure SetVisibilityOnServer()
	
	Items.MasterDataGroup.Visible = Not Object.SettingsMode = "CashExchange" And Not Object.SettingsMode = "ExchangeOfUPRMC";
	
	Items.DocumentsExportStartDate.Enabled =
		?(Object.DocumentsSendingRules = "AutoSynchronization", True, False);
		
	Items.DoNotSendDocumentsRadioButton.Enabled =
		?(Not Object.CatalogsSendingRules = "SynchronizeAsNeeded", True, False);
		
	Items.DocumentDetailsDontSend.Enabled =
		?(Not Object.CatalogsSendingRules = "SynchronizeAsNeeded", True, False);
		
	Items.DocumentsGroup.ChildItems.SendDocumentsModeGroup.Enabled =
		?(Not Object.CatalogsSendingRules = "NotSynchronize", True, False);
		
	Items.GroupSettingUpSelections.Enabled =
		?((Object.CatalogsSendingRules <> "NotSynchronize"
			Or Object.DocumentsSendingRules <> "NotSynchronize"), True, False);
	
	Items.DataReceivingRules.Visible = Not StandardSubsystemsServer.IsBaseConfigurationVersion();
	
	VisibilityOfCostAccounts = (Object.DocumentsSendingRules <> "NotSynchronize") 
		And Not (Object.SettingsMode = "CashExchange" Or Object.SettingsMode = "ExchangeUP2ZUP3");
	Items.DefaultAccountGroup.Visible = VisibilityOfCostAccounts;
		
#Region AdditionalFiltersSettingsGroup
	
	#Region AccountingSections
	// Availability of uploaded accounting sections.
	Items.GroupOfPagesSelectionByAccountingSections.Visible = Not (Object.SettingsMode = "ExchangeUP2ZUP3"
		Or Object.SettingsMode = "CashExchange"
		Or Object.SettingsMode = "ExchangeOfUPRMC");	
	If Items.GroupOfPagesSelectionByAccountingSections.Visible Then
		Items.GroupSelectingModeForUnloadingAccountingPartitions.Enabled = Object.DocumentsSendingRules <> "NotSynchronize";
		Items.GroupOfPagesSelectionByAccountingSections.Enabled = Object.DocumentsSendingRules <> "NotSynchronize"; 
		Items.GroupSelectionByTypeOfDocuments.Enabled = Object.DocumentsSendingRules <> "NotSynchronize"; 
		Items.OpenListOfSelectedAccountingSections.Enabled = ModeForUploadingAccountingSections = 1;
		Items.UploadGroupByDocumentType.Enabled = Object.UseFilterByAccountingSectionAndDocument;
	EndIf; 
	#EndRegion   
	
	#Region DocumentsKinds
	Items.OpenDocumentSelectionForm.Enabled = Object.DocumentsSendingRules <> "NotSynchronize";//Document Loading mode = 1;
	#EndRegion
	
	#Region FilterByCompaniesPagesGroup
	
	Items.FilterByCompaniesPagesGroup.Visible = GetFunctionalOption("UseMultipleCompanies")
		And Not Object.SettingsMode = "ExchangeOfUPRMC";
	
	If Items.FilterByCompaniesPagesGroup.Visible Then
		
		Items.FilterByCompaniesPagesGroup.Enabled = True;
		Items.FilterByCompaniesPagesGroup.CurrentPage = 
			Items.FilterByCompaniesPageGroup;
		
		// Visibility of the management organization and selection option
		UseManagementCompany =
			GetFunctionalOption("UseManagementCompany")
				And Not Object.SettingsMode = "ExchangeUP2ZUP3";
				
		// Visibility of the management organization and the selection option.
		Items.GroupManagementOrganizationSelection.Visible = UseManagementCompany;
		
		If Object.CatalogsSendingRules = "NotSynchronize" Then
			Items.FilterByCompaniesPagesGroup.Enabled = False;
		Else
			
			Items.OpenSelectedCompaniesList.Enabled = Object.UseFilterByCompanies;
			
			If Items.GroupManagementOrganizationSelection.Visible Then
				Items.PageGroupSelectionOptionSelection.CurrentPage = 
					Items.GroupPageSelectionSwitch;
			Else
				
				Items.PageGroupSelectionOptionSelection.CurrentPage = 
					Items.GroupPageSelectionFlag;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	SetGroupVisibilityOnServer(Items, "GroupingSelections");
	SetGroupVisibilityOnServer(Items, "GroupSettingUpSelections");
	#EndRegion
	
#EndRegion
	
#Region OthersGroup

#Region InformBalanceWarehouses
	
	WorkIsExecutedViaSalesRepresentatives = GetFunctionalOption("WorkIsExecutedViaSalesRepresentatives");
	
	// Visibility of unloaded warehouses for inform. leftovers.
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"GroupSettingsSendInformation",
		"Visible",
		Object.SettingsMode <> "ExchangeUP2ZUP3" 
		And Object.SettingsMode <> ExchangePlans.DataSynchronizationViaUniversalFormat.IdOfExchangeSetupBP30()
		And Object.SettingsMode <> ExchangePlans.DataSynchronizationViaUniversalFormat.IdOfExchangeSetupBPCORP30());
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"GroupSettingsSendInformation",
		"Enabled", Object.CatalogsSendingRules <> "NotSynchronize");
		
	If Items.GroupSettingsSendInformation.Visible Then
		
		Items.FlagForSendingInformativeBalances.Visible           = True;
		Items.GroupPagesInformativeInventoryBalances.Visible = Object.UploadInformativeBalance
			And Object.SettingsMode <> "ExchangeOfUPRMC";
		
		Items.GroupSendInformBalancesToWarehouses.Enabled = WorkIsExecutedViaSalesRepresentatives;
		
	EndIf;
	
#EndRegion

#Region OnlyProductListWithBalances
	
	// Visibility of the "Upload only Product items with Balances" attribute
	Items.UploadOnlyProductItemsWithBalancesInGroup.Visible = Object.SettingsMode = "ExchangeOfUPRMC";
	
#EndRegion

#Region TypesOfPrices
	
	// Visibility of the uploaded price types.
	Items.SettingPriceTypesGroup.Visible = Object.SettingsMode <> "ExchangeUP2ZUP3"
		And Object.SettingsMode <> "ExchangeOfUPRMC" And UseSeveralPriceTypes;
	
	If Items.SettingPriceTypesGroup.Visible Then
		
		Items.PriceViewField.AutoMarkIncomplete = Object.SettingsMode = "CashExchange"
			And UseSeveralPriceTypes;
		
		If Object.SettingsMode = "CashExchange" Then
			Items.SettingPriceTypesGroup.CurrentPage = Items.ProductPriceGroup;
			Items.SettingPriceTypesGroup.Visible = UseSeveralPriceTypes;
		Else
			Items.SettingPriceTypesGroup.CurrentPage = Items.GroupIncludesProductPriceTypes;
			
			If Object.UploadProductPrices And UseSeveralPriceTypes Then
				Items.PageGroupSendProductPriceTypes.CurrentPage = 
					Items.GroupPageSelectPriceTypesCommand;
			Else
				Items.PageGroupSendProductPriceTypes.CurrentPage = 
					Items.GroupPageSelectPriceTypesCommandEmpty;
			EndIf;
			
			If Object.CatalogsSendingRules = "NotSynchronize" Then
				Items.GroupIncludesProductPriceTypes.Enabled = False;
			Else
				Items.GroupIncludesProductPriceTypes.Enabled = True;
			EndIf;
		EndIf;
	EndIf;
	
#EndRegion

#Region FilterByCouriers
	
	// Visibility of the filter for unloaded couriers.
	Items.CourierFilterGroup.Visible = Object.SettingsMode <> "ExchangeUP2ZUP3"
		And Object.SettingsMode <> "ExchangeOfUPRMC";
	
	If Items.CourierFilterGroup.Visible Then
		
		Items.UseCourierSelection.Visible = True;

		If Object.UseCourierSelection Then
			Items.OpenListOfCouriers.Visible = True;
		Else
			Items.OpenListOfCouriers.Visible = False;
		EndIf;
		
		Items.CourierFilterGroup.Enabled = Object.CatalogsSendingRules <> "NotSynchronize";
		
	EndIf;
	
#EndRegion

#Region FilterByIndividuals
	
	// Visibility of the uploaded individuals filter.
	Items.FilterGroupForIndividuals.Visible = Object.SettingsMode = "ExchangeOfUPRMC";
	
	If Items.FilterGroupForIndividuals.Visible Then
		
		Items.UseFilterByPersons.Visible = True;
		Items.OpenListOfIndividuals.Visible = Object.UseFilterByPersons;
		
	EndIf;
	
#EndRegion

#Region CashRegisterFilterByCashier
	
	// Cash register filter visibility by yandex.Checkout.
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"FilterGroupByCashAccountCashRegister",
		"Visible",
		 Object.SettingsMode = "ExchangeOfUPRMC");
		 
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"CashRegisterFilterGroupByCashRegisters",
		"Visible",
		Object.SettingsMode <> "ExchangeUP2ZUP3" And Object.SettingsMode <> "ExchangeOfUPRMC" 
		And Object.SettingsMode <> "CashExchange");
	
	If Items.CashRegisterFilterGroupByCashRegisters.Visible Then
		
		Items.UseFilterByCashRegisters.Visible = True;

		If Object.UseFilterByCashRegisters Then
			Items.OpenListOfCashRegisterSalesRegisters.Visible = True;
		Else
			Items.OpenListOfCashRegisterSalesRegisters.Visible = False;
		EndIf;
		
		Items.CashRegisterFilterGroupByCashRegisters.Enabled = Object.CatalogsSendingRules <> "NotSynchronize";
		
	EndIf;
	
#EndRegion

#Region FilterByAcquiringTerminals
	
	// Visibility of the filter of the acquiring terminals being unloaded.
	Items.FilterGroupByAcquiringTerminals.Visible = Object.SettingsMode <> "ExchangeUP2ZUP3";
	
	If Items.FilterGroupByAcquiringTerminals.Visible Then
		
		Items.UseFilterByPOSTerminals.Visible = True;
		Items.OpenListOfAcquiringTerminals.Visible = Object.UseFilterByPOSTerminals;
		Items.FilterGroupByAcquiringTerminals.Enabled = Object.DocumentsSendingRules <> "NotSynchronize";
	EndIf;
	
#EndRegion
	
#Region FilterByAcquiringContracts

	// Visibility of the filter of the acquiring terminals being unloaded.
	Items.FilterGroupUnderAcquiringContracts.Visible = (Object.SettingsMode = "ExchangeOfUPRMC")
		And Not FormatVersionIsBelow(Object.ExchangeFormatVersion, "1.19");

	If Items.FilterGroupUnderAcquiringContracts.Visible Then

		Items.UseFilterByPaymentSystemContracts.Visible = True;
		Items.OpenListOfAcquiringContracts.Visible = Object.UseFilterByPaymentSystemContracts;
		Items.FilterGroupUnderAcquiringContracts.Enabled = Object.DocumentsSendingRules <> "NotSynchronize";
	EndIf;

#EndRegion

#Region WarehousesFilter
	
	// Visibility of the unloaded warehouses filter.
	Items.GroupFilterByWarehouse.Visible = Object.SettingsMode <> "ExchangeUP2ZUP3"
		And Object.SettingsMode <> "ExchangeOfUPRMC"
		And UseSeveralWarehouses;
	
	If Items.GroupFilterByWarehouse.Visible Then
		
		Items.UseWarehouseSelection.Visible = True;

		If Object.UseFilterByWarehouses Then
			Items.OpenListOfDepotsToSend.Visible = True;
		Else
			Items.OpenListOfDepotsToSend.Visible = False;
		EndIf;
		
		Items.GroupFilterByWarehouse.Enabled = Object.CatalogsSendingRules <> "NotSynchronize";
		
	EndIf;
	
#EndRegion

#Region UploadAnalyticsByWarehouseGroup
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"UploadAnalyticsByWarehouseGroup",
		"Visible", Object.SettingsMode <> "ExchangeUP2ZUP3" And Object.SettingsMode <> "ExchangeOfUPRMC");
			
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"UploadAnalyticsByWarehouseGroup",
		"Enabled", Object.DocumentsSendingRules <> "NotSynchronize");
		
#EndRegion

#Region GroupUnloadMarkingData
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"GroupUnloadMarkingData",
		"Visible", False);
			
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"GroupUnloadMarkingData",
		"Enabled", False);
		
	
#EndRegion

#Region GroupRulesForCreatingCounterpartyAgreements

	Items.GroupRulesForCreatingCounterpartyAgreements.Visible = Object.SettingsMode <> "ExchangeUP2ZUP3"
		And Object.SettingsMode <> "ExchangeOfUPRMC";
	Items.RulesForCreatingCounterpartyAgreementsField.AutoMarkIncomplete = Object.SettingsMode <> "ExchangeUP2ZUP3"
		And Object.SettingsMode <> "ExchangeOfUPRMC";
	
	If Items.GroupRulesForCreatingCounterpartyAgreements.Visible Then
		
		Items.GroupRulesForCreatingCounterpartyAgreements.Enabled = Object.DocumentsSendingRules <> "NotSynchronize";
		
		TMCommonUseClientServer.SetFormItemProperty(
			Items,
			"RulesForCreatingCounterpartyAgreementsField",
			"Enabled",
			Items.RulesForCreatingCounterpartyAgreementsField.ChoiceList.Count() > 1);
			
	EndIf;
#EndRegion

#Region PeriodEndClosingDateGroup
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"PeriodEndClosingDateGroup",
		"Visible",
		GetFunctionalOption("UsePeriodClosingDates"));
#EndRegion
	
	SetGroupVisibilityOnServer(Items, "CompositionOfOtherSettingsGroup");
	If Object.SettingsMode = "ExchangeUP2ZUP3" Then
		Items.OthersGroup.Visible = False;
	Else
		SetGroupVisibilityOnServer(Items, "OthersGroup");
	EndIf;
#EndRegion
	
#Region DataReceivingRules
Items.AllowDataImportToBaseVersion.Visible = ?(StandardSubsystemsServer.IsBaseConfigurationVersion(), True, False);
#Region InformationReceivedDataCompositionSettingsGroup
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"InformationReceivedDataCompositionSettingsGroup",
		"Visible",
		GetFunctionalOption("UseImportForbidDates")
			Or Not Object.SettingsMode = "ExchangeUP2ZUP3");
#EndRegion
	
#Region GroupDateWhenDataWasBanned
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"GroupDateWhenDataWasBanned",
		"Visible",
		GetFunctionalOption("UseImportForbidDates"));
#EndRegion
	
#Region DefaultWarehouseGroup
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"DefaultWarehouseGroup",
		"Visible",
		Not Object.SettingsMode = "ExchangeUP2ZUP3" And Not Object.SettingsMode = "ExchangeOfUPRMC");
#EndRegion 

#Region AcquiringTerminalGroupByDefault
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"AcquiringTerminalGroupByDefault",
		"Visible",
		(Object.SettingsMode = "ExchangeOfUPRMC" And FormatVersionIsBelow(Object.ExchangeFormatVersion, "1.17")
			Or Object.SettingsMode <> "ExchangeUP2ZUP3"));
#EndRegion  

#Region GroupOffsettingOfAdvances
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"GroupOffsettingOfAdvances",
		"Enabled", Object.DocumentsSendingRules <> "NotSynchronize");
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"GroupOffsettingOfAdvances",
		"Visible", Not Object.SettingsMode = "ExchangeUP2ZUP3");
		
#EndRegion
#Region DonTUploadImagesGroup
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"DonTUploadImagesGroup",
		"Enabled", Object.CatalogsSendingRules <> "NotSynchronize");
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"DonTUploadImagesGroup",
		"Visible", Not Object.SettingsMode = "ExchangeUP2ZUP3");
		
#EndRegion
       SetGroupVisibilityOnServer(Items, "DataReceivingRules");
#EndRegion	
	
	UpdateNameOfFormCommands();
	
EndProcedure

&AtServer
Function FormAgreements()
	
	Return (Object.DocumentsSendingRules <> "NotSynchronize" And Object.SettingsMode <> "ExchangeUP2ZUP3");
	
EndFunction

&AtServer
Procedure UpdateObjectData(FillParameters)
	
	NameOfTableToFillIn = FillParameters.NameOfTableToFillIn;
	
	Object[FillParameters.NameOfTableToFillIn].Clear();
	
	SelectedValues = GetFromTempStorage(FillParameters.AddressOfTableInTemporaryStorage); // ValueTable
	
	If SelectedValues.Count() > 0 Then 
		
		If SelectedValues.Columns.Find("Id") <> Undefined 
			And SelectedValues.Columns.Find("Presentation") <> Undefined Then
			For Each TableRow In SelectedValues Do
				NewRow = Object[NameOfTableToFillIn].Add();
				NewRow[FillParameters.NameOfColumnToFillIn] = TableRow.Presentation;
			EndDo; 
		ElsIf TypeOf(SelectedValues) = Type("ValueTable") Then
			For Each TableRow In SelectedValues Do
				
				If TableRow.Use Then
					NewRow = Object[NameOfTableToFillIn].Add();
					FillPropertyValues(NewRow, TableRow);
				EndIf;
				
			EndDo;
			
		Else
			SelectedValues.Columns.Presentation.Name = FillParameters.NameOfColumnToFillIn;
			Object[FillParameters.NameOfTableToFillIn].Load(SelectedValues);
		EndIf;
		
	EndIf;
  
	If  FillParameters.NameOfTableToFillIn = "Companies" Then
		AdjustmentOfSettingsWhenChangingOrganization();
	EndIf;
	If FillParameters.NameOfTableToFillIn = "ProductPricesTypes" Then
		Object.UploadProductPrices = (SelectedValues.Count() <> 0);
	EndIf;  
	If FillParameters.NameOfTableToFillIn = "Warehouses" Then
		Object.UseFilterByWarehouses = (SelectedValues.Count() <> 0);
	EndIf;
	If FillParameters.NameOfTableToFillIn = "Couriers" Then
		Object.UseCourierSelection = (SelectedValues.Count() <> 0);
	EndIf;
	If FillParameters.NameOfTableToFillIn = "POSTerminals" Then
		Object.UseFilterByPOSTerminals = (SelectedValues.Count() <> 0);
	EndIf;
	If FillParameters.NameOfTableToFillIn = "CashRegisters" Then
		Object.UseFilterByCashRegisters = (SelectedValues.Count() <> 0); 
		UpdateDependentSelections();
	EndIf; 
	If FillParameters.NameOfTableToFillIn = "DocumentsKinds" Then
		Object.UseFilterByAccountingSectionAndDocument = (SelectedValues.Count() <> 0);
	EndIf;  
	UpdateNameOfFormCommands();
	
EndProcedure

&AtServer
Procedure AdjustmentOfSettingsWhenChangingOrganization()

	If Object.SettingsMode <> "CashExchange" 
		Or Not Object.UseFilterByCompanies
		Or Object.Companies.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Parameters.Insert("CurrentEqTerminals", 
		Object.POSTerminals.Unload().UnloadColumn("POSTerminal"));
	Query.Parameters.Insert("CurrentOrganizations", 
		Object.Companies.Unload().UnloadColumn("Organization"));
	Query.Text = 
	"SELECT
	|	POSTerminals.Ref AS POSTerminal
	|FROM
	|	Catalog.POSTerminals AS POSTerminals
	|WHERE
	|	POSTerminals.Ref IN(&CurrentEqTerminals)
	|	AND POSTerminals.Owner.Organization IN(&CurrentOrganizations)";
	
	Object.POSTerminals.Clear();
	Object.POSTerminals.Load(Query.Execute().Unload());

EndProcedure

&AtServer
Procedure UpdateNameOfFormCommands()
	
	// Update the header of the selected organizations
	If Object.Companies.Count() > 0 Then
		
		SelectedCompanies = Object.Companies.Unload().UnloadColumn("Organization");
		NewOrganizationsTitle = StrConcat(SelectedCompanies, ",");
		
	Else
		
		NewOrganizationsTitle = NStr("vi = 'Chọn doanh nghiệp';
									|ru = 'Выбрать организации';
									|en = 'Select companies'; fa = 'انتخاب شرکت‌ها';
									|it = 'Selezionare aziende';
									|pl = 'Wybierz firmę';
									|tr = 'İş yerini seç'");
		
	EndIf;
	
	Items.OpenSelectedCompaniesList.Title = NewOrganizationsTitle;
	
	// Update the header of the selected types of prices
	If Object.ProductPricesTypes.Count() > 0 Then
		NewHeadingTypesOfPrices = "";
		SelectedTypesOfPrices = Object.ProductPricesTypes.Unload().UnloadColumn("ProductPricesType"); // Array
		FirstTableRow = SelectedTypesOfPrices[0];
		Description = Common.ObjectAttributeValue(FirstTableRow, "Description");
		GenerateFilterTitle(SelectedTypesOfPrices.Count(), Description, NewHeadingTypesOfPrices)
	
	Else
		
		NewHeadingTypesOfPrices = NStr("vi = 'Chọn dạng giá';
										|ru = 'Выбрать виды цен';
										|en = 'Select price types'; fa = 'انتخاب انواع قیمت';
										|it = 'Selezionare tipologie di prezzi';
										|pl = 'Wybierz rodzaje cen';
										|tr = 'Fiyat türlerini seç'");
		
	EndIf;
	
	Items.OpenListOfProductPriceTypesToSend.Title = NewHeadingTypesOfPrices;
	
	If Object.WarehousesOfInformativeBalance.Count() > 0 Then
		NewHeadlineWarehousesInformBalances = "";
		SelectedInformationBalanceWarehouses = Object.WarehousesOfInformativeBalance.Unload().UnloadColumn("Warehouse"); // Array
		FirstTableRow = SelectedInformationBalanceWarehouses[0];
		Description = Common.ObjectAttributeValue(FirstTableRow, "Description");
		GenerateFilterTitle(SelectedInformationBalanceWarehouses.Count(), Description,NewHeadlineWarehousesInformBalances);
	Else
		
		NewHeadlineWarehousesInformBalances = NStr("vi = 'Chọn kho';
													|ru = 'Выбрать склады';
													|en = 'Select warehouses'; fa = 'انتخاب انبارها';
													|it = 'Selezionare magazzini';
													|pl = 'Wybierz magazyny';
													|tr = 'Ambarları seç'");
		
	EndIf;
	
	Items.OpenListOfSentWarehousesInformLeftovers.Title = NewHeadlineWarehousesInformBalances;
	
	NewTitleAccountingSections = NStr("vi = 'Lọc theo dạng chứng từ';
										|ru = 'Фильтр по видам документов';
										|en = 'Filter by document kind'; fa = 'فیلتر بر اساس نوع سند';
										|it = 'Фильтр по видам документов';
										|pl = 'Filter by document kind';
										|tr = 'Belge türüne göre filtre'");
	
	If Not Object.DocumentsKinds.Count() = 0 Then
		NewTitleAccountingSections = "";
		SelectedAccountingSections = Object.DocumentsKinds.Unload().UnloadColumn("Presentation"); // Array
		Description = SelectedAccountingSections[0]; // String
	    GenerateFilterTitle(SelectedAccountingSections.Count(), Description,NewTitleAccountingSections);
	EndIf;
		
	Items.OpenDocumentSelectionForm.Title = NewTitleAccountingSections;
	
	// Update the header of the selected warehouses
	If Object.Warehouses.Count() > 0 Then
		NewWarehouseTitle = "";
		SelectedWarehouses = Object.Warehouses.Unload().UnloadColumn("Warehouse"); // Array
		FirstTableRow = SelectedWarehouses[0];
		Description = Common.ObjectAttributeValue(FirstTableRow, "Description");
 		GenerateFilterTitle(SelectedWarehouses.Count(), Description,NewWarehouseTitle);
	Else
		NewWarehouseTitle = NStr("vi = 'Chọn kho';
								|ru = 'Выбрать склады';
								|en = 'Select warehouses'; fa = 'انتخاب انبارها';
								|it = 'Selezionare magazzini';
								|pl = 'Wybierz magazyny';
								|tr = 'Ambarları seç'");
	EndIf;
	
	Items.OpenListOfDepotsToSend.Title = NewWarehouseTitle;
	
	// Update the title of the selected couriers
	If Object.Couriers.Count() > 0 Then
		NewTitleOfCourierList = "";
		SelectedCouriers = Object.Couriers.Unload().UnloadColumn("Courier"); // Array
		FirstTableRow = SelectedCouriers[0];
		Description = Common.ObjectAttributeValue(FirstTableRow, "Description");
		GenerateFilterTitle(SelectedCouriers.Count(), Description,NewTitleOfCourierList);
	Else
		NewTitleOfCourierList = NStr("vi = 'Chọn người vận chuyển';
									|ru = 'Выбрать курьеров';
									|en = 'Select couriers'; fa = 'انتخاب پیک‌ها';
									|it = 'Selezionare corrieri';
									|pl = 'Wybierz kurierów';
									|tr = 'Kuryeleri seç'");
	EndIf;
	
	Items.OpenListOfCouriers.Title = NewTitleOfCourierList;
	
	// Update the header of the selected individuals
	If Object.Persons.Count() > 0 Then
		NewListTitle = "";
		SelectedIndividuals = Object.Persons.Unload().UnloadColumn("Individual"); // Array
		FirstTableRow = SelectedIndividuals[0];
		Description = Common.ObjectAttributeValue(FirstTableRow, "Description");
		GenerateFilterTitle(SelectedIndividuals.Count(), Description,NewListTitle);
	Else
		NewListTitle = NStr("vi = 'Chọn cá nhân';
							|ru = 'Выбрать физические лица';
							|en = 'Select persons'; fa = 'انتخاب اشخاص';
							|it = 'Selezionare persone fisiche';
							|pl = 'Wybierz osób fizycznych';
							|tr = 'Gerçek kişileri seç'");
	EndIf;
	
	Items.OpenListOfIndividuals.Title = NewListTitle;
	
	// Update the header of the selected acquiring terminals
	If Object.POSTerminals.Count() > 0 Then
		NewListTitle = "";
		SelectedAcquiringTerminals = Object.POSTerminals.Unload().UnloadColumn("POSTerminal"); // Array
		FirstTableRow = SelectedAcquiringTerminals[0];
		Description = Common.ObjectAttributeValue(FirstTableRow, "Description");
		GenerateFilterTitle(SelectedAcquiringTerminals.Count(), Description,NewListTitle);
	Else
		NewListTitle = NStr("vi = 'Chọn thiết bị thanh toán thẻ';
							|ru = 'Выбрать эквайринговые терминалы';
							|en = 'Select POS terminals'; fa = 'انتخاب پایانه‌های POS';
							|it = 'Selezionare terminali di acquisizione';
							|pl = 'Wybierz terminale płatnicze';
							|tr = 'PoS terminallerini seç'");
	EndIf;
	
	Items.OpenListOfAcquiringTerminals.Title = NewListTitle;
	
	// Update the header of the selected acquiring Contracts
	If Object.PaymentSystemContracts.Count() > 0 Then
		
		SelectedAcquiringContracts = Object.PaymentSystemContracts.Unload().UnloadColumn("ConnectionContract");
		NewListTitle = StrConcat(SelectedAcquiringContracts, ",");
		
	Else
		NewListTitle = NStr("vi = 'Chọn hợp đồng kết nối';
							|ru = 'Выбрать договоры подключения';
							|en = 'Select payment system contracts'; fa = 'انتخاب قراردادهای سیستم پرداخت';
							|it = 'Выбрать договоры подключения';
							|pl = 'Select payment system contracts';
							|tr = 'Bağlantı sözleşmeleri seç'");
	EndIf;
	
	Items.OpenListOfAcquiringContracts.Title = NewListTitle;
	
	// Update the header of the selected Cash register
	If Object.CashRegisters.Count() > 0 Then
		NewTitleOfCashRegisterCashAccount = "";
		SelectedCashAccountsCashRegister = Object.CashRegisters.Unload().UnloadColumn("CashRegister"); // Array
		FirstTableRow = SelectedCashAccountsCashRegister[0];
		Description = Common.ObjectAttributeValue(FirstTableRow, "Description");
		GenerateFilterTitle(SelectedCashAccountsCashRegister.Count(), Description,NewTitleOfCashRegisterCashAccount);
	Else
		
		NewTitleOfCashRegisterCashAccount = NStr("vi = 'Chọn quầy thu ngân';
												|ru = 'Выбрать кассы ККМ';
												|en = 'Select cash registers'; fa = 'انتخاب صندوق‌های فروش';
												|it = 'Выбрать кассы ККМ';
												|pl = 'Select cash registers';
												|tr = 'Yazar kasaları seç'");
		
	EndIf;
	
	Items.OpenListOfCashRegisterSalesRegisters.Title   = NewTitleOfCashRegisterCashAccount;
	Items.SpecifyListOfCashRegisterCashAccountsButton.Title = NewTitleOfCashRegisterCashAccount;
		
EndProcedure
	
&AtServer
Procedure UpdateListOfSelectedVersionsOfExchangeFormat()
	ListOfFormatVersions = Items.ExchangeFormatVersion.ChoiceList;
	ListOfFormatVersions.Clear();
	
	FormatVersions = New Map;
	TMDataExchange.AvailableVersionsOfUniversalFormat(FormatVersions);
	
	For Each FormatVersion In FormatVersions Do
		ListOfFormatVersions.Add(FormatVersion.Key);
	EndDo;
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL) 
	
	If Not ValueIsFilled(FormattedStringURL) Then
		
		Return;
		
	EndIf;
	
	If FormattedStringURL = "OpenSalesSettingsForm" Then
		
		OpenForm("DataProcessor.TMAdministrationPanel.Form.Sales", New Structure);
		
	EndIf;
	
EndProcedure

&AtServer
Function GenerateArrayOfSelectedValues(FormParameters)
	
	TabularSection           = Object[FormParameters.NameOfFormElementToFillIn];
	TableOfSelectedValues = TabularSection.Unload(,FormParameters.NameOfFormElementDetailsToFillIn);
	ArrayOfSelectedValues_  = TableOfSelectedValues.UnloadColumn(FormParameters.NameOfFormElementDetailsToFillIn);
	
	Return ArrayOfSelectedValues_;

EndFunction

&AtClient
Procedure SetSynchronizationRestrictionConditions()
	
	If CatalogsFilterRule = "Filter" Then
		
		Object.UseFilterByCompanies = True;
		Object.UnloadManagementCompany = False;
		
	ElsIf CatalogsFilterRule = "ManOrganization" Then
		
		Object.UseFilterByCompanies = False;
		Object.UnloadManagementCompany = True;
		
	ElsIf CatalogsFilterRule = "NoFilter" Then
		
		Object.UseFilterByCompanies = False;
		Object.UnloadManagementCompany = False;
		
	EndIf;
	
	If ModeForUploadingAccountingSections = 1 Then
		Object.UseFilterByAccountingSections = True;
	Else
		Object.UseFilterByAccountingSections = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetGroupVisibilityOnServer(FormItems, GroupName)
	
	FormGroup = FormItems.Find(GroupName);
	
	If FormGroup = Undefined
		Or Not TypeOf(FormGroup) = Type("FormGroup") Then
		
		Return;
		
	EndIf;
	
	Visible = False;
	
	For Each SubordinateItem In FormGroup.ChildItems Do
		
		If Not TypeOf(SubordinateItem) = Type("FormGroup") Then
			Continue; // we set visibility only by visibility of child groups of the first nesting level
		EndIf;
		
		Visible = Visible Or SubordinateItem.Visible;
			
	EndDo;
	
	FormGroup.Visible = Visible;
	
EndProcedure

&AtServer
Procedure CreateListOfContractFormationRules()
	
	// Let's form a selection list for the props "Rules for creating Counteragents' agreements"
	ListOfContractFormationRules = ExchangePlans.DataSynchronizationViaUniversalFormat.ListOfContractFormationRules();
	Items.RulesForCreatingCounterpartyAgreementsField.ChoiceList.Clear();
	For Each ElementOfRules In ListOfContractFormationRules Do
		Items.RulesForCreatingCounterpartyAgreementsField.ChoiceList.Add(ElementOfRules.Value, ElementOfRules.Presentation);
	EndDo;
	
	If ListOfContractFormationRules.Count() = 1 Then
		Object.RulesForCreatingCounterpartyContracts = ListOfContractFormationRules[0].Value;
	EndIf;
	
	If ValueIsFilled(Object.RulesForCreatingCounterpartyContracts)
		And ListOfContractFormationRules.FindByValue(Object.RulesForCreatingCounterpartyContracts) = Undefined Then
		
		Object.RulesForCreatingCounterpartyContracts = "";
	EndIf;
	
EndProcedure

// It is called when the Cash register structure changes (for 1C:CWP)
&AtServer
Procedure UpdateDependentSelections()
	
	If Object.SettingsMode <> "ExchangeOfUPRMC" Then
		Return;
	EndIf;
	
	If FormatVersionIsBelow(Object.ExchangeFormatVersion, "1.17") And ValueIsFilled(CashRegister) Then
		
		Object.CashRegisters.Clear();
		String = Object.CashRegisters.Add();
		String.CashRegister = CashRegister;
		Object.UseFilterByCashRegisters = True;
		
	EndIf;
	
	ExchangePlans.DataSynchronizationViaUniversalFormat.UpdateDependentSelections(Object);
	
EndProcedure

&AtServer
Function ArrayOfSettingsTableObjects(TabularSectionName, ColumnName)

	Return Object[TabularSectionName].Unload().UnloadColumn(ColumnName);

EndFunction

&AtServer
Procedure AutocompletionByDocumentType()
	SettingID = Object.SettingsMode;
	If SettingID = "CashExchange" 
		Or SettingID = "ExchangeUP2ZUP3"
		Or SettingID  = "ExchangeOfUPRMC" Then
		Return
	EndIf;
	
	If Object.DocumentsKinds.Count() <> 0 Then
	    Return
	EndIf;  
	Filter = New Structure;  
	Filter.Insert("ToExport", True);
	SectionsArray = Object.AccountingSections.Unload(Filter);
	If Constants.TradeManagement.Get() 
		And SectionsArray.Count() = 5 Then 
		Return;
	ElsIf SectionsArray.Count() = 7 Then
		Return
	EndIf;
	
	ArrayOfSectionsOfExchangePlan = SectionsArray.UnloadColumn("AccountingSection"); 
	ExchangePlans.DataSynchronizationViaUniversalFormat.FillInTypesOfDocumentsForAccountingSections(Object, ArrayOfSectionsOfExchangePlan);
		
EndProcedure

&AtClient
Procedure ReturnOldSettingForAccountingSections(Command)
	ModeForUploadingAccountingSections = 1;
	Items.ModeSwitchForUnloadingAccountingSectionsWithoutSelection.Visible = Not Items.ModeSwitchForUnloadingAccountingSectionsWithoutSelection.Visible; 
	Items.ModeSwitchForUnloadingAccountingSectionsWithSelection.Visible = Not Items.ModeSwitchForUnloadingAccountingSectionsWithSelection.Visible; 
	Items.OpenListOfSelectedAccountingSections.Visible = Not Items.OpenListOfSelectedAccountingSections.Visible;  
	Items.OpenListOfSelectedAccountingSections.Enabled = Items.OpenListOfSelectedAccountingSections.Visible;
    Items.DocumentUploadMode.Visible = Not Items.DocumentUploadMode.Visible;
	Items.ClearSelectionByDocumentType.Visible = Not Items.ClearSelectionByDocumentType.Visible;
	Items.OpenDocumentSelectionForm.Visible = Not Items.OpenDocumentSelectionForm.Visible;
EndProcedure

&AtServer
Procedure ManualUpdateOnServer() 
	FullObjectName = "ExchangePlan.DataSynchronizationViaUniversalFormat";
	//Updateedata = Update of the information database.Data for updating in my Threading Processor(Parameters);
	ConfigurationVariants = New ValueList;
	ConfigurationVariants.Add("CashExchange");
	ConfigurationVariants.Add("ExchangeUP2ZUP3");
	ConfigurationVariants.Add("ExchangeOfUPRMC");
	ThisIsUT = Constants.TradeManagement.Get();
	Query = New Query;
	Query.Text = 
		"SELECT
		|	DataSynchronizationViaUniversalFormatAccountingSections.Ref AS ElementSubAsset,
		|	DataSynchronizationViaUniversalFormatAccountingSections.AccountingSection AS AccountingSection
		|INTO TT
		|FROM
		|	ExchangePlan.DataSynchronizationViaUniversalFormat.AccountingSections AS DataSynchronizationViaUniversalFormatAccountingSections
		|WHERE
		|	NOT DataSynchronizationViaUniversalFormatAccountingSections.Ref.DeletionMark
		|	AND NOT DataSynchronizationViaUniversalFormatAccountingSections.Ref.SettingsMode IN (&ConfigurationVariants)
		|	AND DataSynchronizationViaUniversalFormatAccountingSections.ToExport
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataSynchronizationViaUniversalDocumentTypesFormat.Ref AS ElementSubAsset,
		|	ISNULL(COUNT(DataSynchronizationViaUniversalDocumentTypesFormat.MetadataObjectName), 0) AS DocumentsCount
		|INTO FilterByDocs
		|FROM
		|	ExchangePlan.DataSynchronizationViaUniversalFormat.DocumentsKinds AS DataSynchronizationViaUniversalDocumentTypesFormat
		|WHERE
		|	NOT DataSynchronizationViaUniversalDocumentTypesFormat.Ref.DeletionMark
		|	AND NOT DataSynchronizationViaUniversalDocumentTypesFormat.Ref.SettingsMode IN (&ConfigurationVariants)
		|
		|GROUP BY
		|	DataSynchronizationViaUniversalDocumentTypesFormat.Ref
		|
		|HAVING
		|	COUNT(DataSynchronizationViaUniversalDocumentTypesFormat.MetadataObjectName) > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT.ElementSubAsset AS ElementSubAsset,
		|	ISNULL(COUNT(TT.AccountingSection),0) AS NumberOfPartitions,
		|	ISNULL(FilterByDocs.DocumentsCount, 0) AS DocumentsCount
		|FROM
		|	TT AS TT
		|		LEFT JOIN FilterByDocs AS FilterByDocs
		|		ON TT.ElementSubAsset = FilterByDocs.ElementSubAsset
		|
		|GROUP BY
		|	TT.ElementSubAsset,
		|	FilterByDocs.DocumentsCount";
	
	Query.SetParameter("ConfigurationVariants", ConfigurationVariants);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf; 
	
	UpdatedData = New Array;
	UpdatedData = QueryResult.Select();
	
	While UpdatedData.Next() Do
		If (ThisIsUT And UpdatedData.NumberOfPartitions = 5) 
			Or  (Not ThisIsUT And UpdatedData.NumberOfPartitions = 7) 
			Or UpdatedData.DocumentsCount > 0 Then
			Continue;
		EndIf;
				
		BeginTransaction();
		Try
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", UpdatedData.ElementSubAsset.Ref);
					
			Block.Lock();
			
			ObjectNode = UpdatedData.ElementSubAsset.GetObject();
			ArrayOfSectionsOfExchangePlan = ObjectNode.AccountingSections.UnloadColumn("AccountingSection");				
			If ObjectNode = Undefined Then 
				InfobaseUpdate.MarkProcessingCompletion(UpdatedData.ElementSubAsset);
			Else
				ExchangePlans.DataSynchronizationViaUniversalFormat.FillInTypesOfDocumentsForAccountingSections(ObjectNode, ArrayOfSectionsOfExchangePlan);
				InfobaseUpdate.WriteObject(ObjectNode, True, False);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), UpdatedData.ElementSubAsset);
			
		EndTry;
		
	EndDo;

EndProcedure
&AtClient
Procedure ManualUpdate(Command)
	ManualUpdateOnServer();
EndProcedure

&AtServerNoContext
Function FormatVersionIsBelow(Val CurrentVersion, Val TargetVersion)
	
	Cur_Version = TMDataExchange.NumberFormatVersion(CurrentVersion);
	WholeVersion = TMDataExchange.NumberFormatVersion(TargetVersion);
	
	Return Cur_Version < WholeVersion;

EndFunction
&AtServer
Procedure GenerateFilterTitle(Count,Description,NewTitle)
	If Count = 1 Then 
		NewTitle = Description;
	ElsIf Count >= 2 Then 
		QuantityByString = String(Count - 1); 
		TemplateOfPresentation = NStr("vi = '%1 (và hơn nữa %2).';
										|ru = '%1 (и еще %2).';
										|en = '%1 (and %2 more).'; fa = '%1 (and %2 more).';
										|it = '%1 (и еще %2).';
										|pl = '%1 (and %2 more).';
										|tr = '%1 (ve dahası %2).'", Common.DefaultLanguageCode());
		NewTitle = StrTemplate(TemplateOfPresentation, Description, QuantityByString);  
	Else
		NewTitle = "";
	EndIf;
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
