&AtClient
Var CatalogFormElements;

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not ValueIsFilled(RegistrationCountry) Then
		RegistrationCountry = Constants.MainCountry.Get();
	EndIf;
	
	ThisIsUT = GetFunctionalOption("TradeManagement");
	Items.GroupLeaseContracts.Visible = Not ThisIsUT;
	Items.GoToDocuments_5.Visible     = Not ThisIsUT;
	Items.WarningRent.Visible = Not ThisIsUT;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CatalogFormElements = MatchingFormElements();
	StartUpdatingForm();
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Not ValueIsFilled(RegistrationCountry) Then
		RegistrationCountry = Constants.MainCountry.Get();
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CurRate_OnChange(Item)
	
	StartUpdatingForm();
	
EndProcedure

&AtClient
Procedure PeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	StartUpdatingForm();
	
EndProcedure

&AtClient
Procedure RegistrationCountryOnChange(Item)
	
	StartUpdatingForm();
	
EndProcedure

&AtClient
Procedure DataItemURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	VATRate = DataItemProcessingOfNavigationLinkATServer(FormattedStringURL);
	
	FormParameters = New Structure();
	FormParameters.Insert("Country",    RegistrationCountry);
	FormParameters.Insert("VATRate", VATRate);
	FormParameters.Insert("Period",    Period);
	
	OpenForm("InformationRegister.ProductsVATRates.Form.Workplace", FormParameters);
	
EndProcedure

&AtClient
Procedure TheseTypesOfItemsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenCatalogForm(FormattedStringURL, "Catalog.ItemKinds.Form.ListForm");
	
EndProcedure

&AtClient
Procedure DataContractsOfCounterpartiesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenCatalogForm(FormattedStringURL, "Catalog.CounterpartyContracts.Form.ListForm", True);
	
EndProcedure 

&AtClient
Procedure TheseContractsBetweenOrganizationsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenCatalogForm(FormattedStringURL, "Catalog.IntercompanyContracts.Form.ListForm", True);

EndProcedure

&AtClient
Procedure TheseLeaseContractsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenCatalogFormLeaseContracts(FormattedStringURL);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	StartUpdatingForm();
	
EndProcedure

&AtClient
Procedure ReplaceEverywhere(Command)
	
	If Not CheckFormCompletion(True) Then
		Return;
	EndIf;
	
	ListOfReferenceBooks = New ValueList;
	ListOfReferenceBooks.Add("Products");
	ListOfReferenceBooks.Add("ItemKinds");
	ListOfReferenceBooks.Add("CounterpartyContracts");
	ListOfReferenceBooks.Add("IntercompanyContracts");
	
	TimeConsumingOperation = StartBidReplacementAtServer(ListOfReferenceBooks);

	CallbackOnCompletion = New CallbackDescription("BidReplacementEnd", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtClient
Procedure ReplaceInFormOfItem(Command)
	
	If Not CheckFormCompletion(False) Then
		Return;
	EndIf;
	
	ListOfReferenceBooks = New ValueList;
	ListOfReferenceBooks.Add("ItemKinds");
	
	TimeConsumingOperation = StartBidReplacementAtServer(ListOfReferenceBooks);

	CallbackOnCompletion = New CallbackDescription("BidReplacementEnd", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtClient
Procedure ReplaceInItem(Command)
	
	If Not CheckFormCompletion(True) Then
		Return;
	EndIf;
	
	ListOfReferenceBooks = New ValueList;
	ListOfReferenceBooks.Add("Products");
	
	TimeConsumingOperation = StartBidReplacementAtServer(ListOfReferenceBooks);

	CallbackOnCompletion = New CallbackDescription("BidReplacementEnd", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure 

&AtClient
Procedure ReplaceInContractsWithContractors(Command) 
	
	If Not CheckFormCompletion(False) Then
		Return;
	EndIf;
	
	ListOfReferenceBooks = New ValueList;
	ListOfReferenceBooks.Add("CounterpartyContracts");
	
	TimeConsumingOperation = StartBidReplacementAtServer(ListOfReferenceBooks);

	CallbackOnCompletion = New CallbackDescription("BidReplacementEnd", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtClient
Procedure ReplaceInContractsBetweenOrganizations(Command)
	
	If Not CheckFormCompletion(False) Then
		Return;
	EndIf;
	
	ListOfReferenceBooks = New ValueList;
	ListOfReferenceBooks.Add("IntercompanyContracts");
	
	TimeConsumingOperation = StartBidReplacementAtServer(ListOfReferenceBooks);

	CallbackOnCompletion = New CallbackDescription("BidReplacementEnd", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtClient
Procedure OpenListOfLeaseContracts(Command)
	OpenForm("Document.LeaseTermAdjustment.Form.ListForm");
	Return ; // It is not used in TM
	
EndProcedure

&AtClient
Procedure OpenDocumentsList(Command)
	OpenForm("Document.ChangeRentalTerms.Form.ListForm");
	Return ; // It is not used in TM
	
EndProcedure


#EndRegion

#Region Private

&AtClient
Procedure StartUpdatingForm()

	TimeConsumingOperation = StartUpdatingFormAtServer();

	CallbackOnCompletion = New CallbackDescription("UpdatingFormEnd", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);

EndProcedure

&AtServer
Function StartUpdatingFormAtServer()
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	
	DataGetParameters = DataProcessors.ReplaceVATRates.DataGetParameters();
	DataGetParameters.CurRate_ = CurRate_;
	DataGetParameters.NewBid   = NewBid;
	DataGetParameters.Period        = Period;
	DataGetParameters.Country        = RegistrationCountry;
	
	FunctionName = "DataProcessors.ReplaceVATRates.GettingDataOnVATRates";
	
	Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters,
		FunctionName, DataGetParameters);
	
EndFunction

&AtClient
Procedure UpdatingFormEnd(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	BettingCatalogData = GetFromTempStorage(Result.ResultAddress);
	DeleteFromTempStorage(Result.ResultAddress);
	
	TemplateRow             = "%4 %1 - <a href = ""%2""> %3 </a>";
	FirstLineTemplateString = "%1 - <a href = ""%2""> %3 </a>";
	Separator = ","; 
	DisplayChangeAllButton = False;
	
	For Each CatalogType In BettingCatalogData Do
		
		CatalogFormElement = CatalogFormElements.Get(CatalogType.Key);
		CatalogFormElement[0] = True;
		Array = New Array();
		
		If ValueIsFilled(CatalogType.Value) Then
			
			CatalogFormElement[2].Visible = True;
			DisplayChangeAllButton = True;
			FirstRow = True;
			For Each VATRate In CatalogType.Value Do
				If ValueIsFilled(VATRate.VATRate) Then
					If VATRate.VATRate = CurRate_ Then
						
						CatalogFormElement[0] = False;
						If CatalogFormElement[1] <> Undefined Then
							ReplaceBidElement = CatalogFormElement[1]; // FormField
							ReplaceBidElement.Title = NStr("vi = 'Thay thế thuế suất';
															|ru = 'Заменить ставку';
															|en = 'Replace the rate'; fa = 'جایگزینی نرخ';
															|it = 'Replace the rate';
															|pl = 'Replace the rate';
															|tr = 'Oranı değiştir'") + " (" + VATRate.Count+")";
						EndIf;
						
					EndIf;
					DeliveryDataLine = StringFunctionsClient.FormattedString(?(FirstRow, FirstLineTemplateString, TemplateRow),
																		String(VATRate.VATRate), VATRate.UID, VATRate.Count, Separator);
					
					Array.Add(DeliveryDataLine);
					FirstRow = False;
					
				EndIf;
			EndDo;
			ReplaceBidElement = CatalogFormElement[3]; // FormField
			ReplaceBidElement.Title = New FormattedString(Array);
		Else
			CatalogFormElement[2].Visible = False;
		EndIf;

	EndDo;

	Items.FormReplaceEverywhere.Enabled = DisplayChangeAllButton;
	SetVisibility1(BettingCatalogData);
	
EndProcedure

&AtClient
Procedure BidReplacementEnd(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	StartUpdatingForm();
	
EndProcedure

&AtServerNoContext
Function DataItemProcessingOfNavigationLinkATServer(UID)
	
	Return Catalogs.VATRates.GetRef(New UUID(UID));
	
EndFunction

&AtClient
Procedure SetVisibility1(AnalyzedCatalogs) 
	
	For Each Catalog In AnalyzedCatalogs Do
		CatalogFormElement = CatalogFormElements.Get(Catalog.Key);
		CatalogFormElement[4].Visible = Not CatalogFormElement[0];
		CatalogFormElement[5].Visible = CatalogFormElement[0];
		If CatalogFormElement[1] <> Undefined Then
			CatalogFormElement[1].Enabled = Not CatalogFormElement[0];
			If CatalogFormElement[0] Then
				ReplaceBidElement = CatalogFormElement[1]; // FormField
				ReplaceBidElement.Title = NStr("vi = 'Thay thế thuế suất';
												|ru = 'Заменить ставку';
												|en = 'Replace the rate'; fa = 'جایگزینی نرخ';
												|it = 'Replace the rate';
												|pl = 'Replace the rate';
												|tr = 'Oranı değiştir'") + " (" + 0 +")";
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure


&AtClient
Procedure OpenCatalogForm(UID, Var_FormName, FilterByPeriod = False)
	
	VATRate = DataItemProcessingOfNavigationLinkATServer(UID);
	
	FormParameters = New Structure();
	FormParameters.Insert("VATRate", VATRate);
	If FilterByPeriod Then
		FormParameters.Insert("Status", PredefinedValue("Enum.CounterpartyContractStatuses.Closed"));
		FormParameters.Insert("TypeOfStatusComparison", DataCompositionComparisonType.NotEqual);
		AvailablePeriods = New ValueList();
		AvailablePeriods.Add(Date(1,1,1));
		AvailablePeriods.Add(Period);
		FormParameters.Insert("ValidityEndDate", AvailablePeriods);
		FormParameters.Insert("TypeOfDateComparison", DataCompositionComparisonType.InList);
	EndIf;
	
	OpenForm(Var_FormName, FormParameters);
	
EndProcedure

&AtClient
Procedure OpenCatalogFormLeaseContracts(UID)
	ReferenceList = ListOfLeaseContracts(UID, Period);
	
	FormParameters = New Structure();
	FormParameters.Insert("References", ReferenceList);
	
	OpenForm("Catalog.LeaseContract.Form.ListForm", FormParameters);
EndProcedure
&AtServerNoContext
Function ListOfLeaseContracts(UID, Period)
	
	VATRate = DataItemProcessingOfNavigationLinkATServer(UID);
	
	Query = New Query;
	Query.SetParameter("Period",    Period);
	Query.SetParameter("VATRate", VATRate);
	
	Query.Text = "SELECT ALLOWED
	|	TermsOfLeaseContractsSliceLast.Contract AS Contract
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(&Period, ) AS TermsOfLeaseContractsSliceLast
	|WHERE
	|	TermsOfLeaseContractsSliceLast.VATRate = &VATRate
	|	AND TermsOfLeaseContractsSliceLast.State <> VALUE(Enum.CounterpartyContractStates.Closed)";
	
	Result = Query.Execute().Select();
	References = New ValueList();
	
	While Result.Next() Do
		References.Add(Result.Contract);
	EndDo;
		
	Return References;
	
EndFunction
&AtServer
Function StartBidReplacementAtServer(ListOfReferenceBooks)
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	
	DataGetParameters = DataProcessors.ReplaceVATRates.DataGetParameters();
	DataGetParameters.CurRate_      = CurRate_;
	DataGetParameters.NewBid        = NewBid;
	DataGetParameters.Period             = Period;
	DataGetParameters.Country             = RegistrationCountry;
	DataGetParameters.ListOfReferenceBooks = ListOfReferenceBooks;
	
	FunctionName = "VATAccountingERP.ReplaceVATRate";
	
	Return TimeConsumingOperations.ExecuteProcedure(ExecutionParameters,
		FunctionName, DataGetParameters);
	
EndFunction

&AtClient
Function CheckFormCompletion(CheckingPeriod)
	
	ClearMessages();
	
	FormFilled = True;
	
	If Not ValueIsFilled(CurRate_) Then
		FormFilled = False;
		ErrorText = NStr("vi = 'Chưa điền trường ""Thuế suất""';
						|ru = 'Поле ""Ставка"" не заполнено';
						|en = 'The ""Rate"" field is required'; fa = 'The ""Rate"" field is required';
						|it = 'The ""Rate"" field is required';
						|pl = 'The ""Rate"" field is required';
						|tr = '""Oran"" alanı doldurulmadı'");
		CommonClient.MessageToUser(
			ErrorText,, "CurRate_");
	EndIf;
	
	If Not ValueIsFilled(NewBid) Then
		FormFilled = False;
		ErrorText = NStr("vi = 'Chưa điền trường ""Thuế suất mới""';
						|ru = 'Поле ""Новая ставка"" не заполнено';
						|en = 'The ""New rate"" field is required'; fa = 'The ""New rate"" field is required';
						|it = 'The ""New rate"" field is required';
						|pl = 'The ""New rate"" field is required';
						|tr = '""Yeni oran"" alanı doldurulmadı'");
		CommonClient.MessageToUser(
			ErrorText,, "NewBid");
	EndIf;
	
	If CheckingPeriod And Not ValueIsFilled(Period) Then
		FormFilled = False;
		ErrorText = NStr("vi = 'Chưa điền trường ""Kỳ""';
						|ru = 'Поле ""Период"" не заполнено';
						|en = 'Period is not filled in'; fa = 'Period is not filled in';
						|it = 'Period is not filled in';
						|pl = 'Period is not filled in';
						|tr = '""Dönem"" alanı doldurulmadı'");
		CommonClient.MessageToUser(
			ErrorText,, "Period");

	EndIf;
	
	Return FormFilled;
	
EndFunction

&AtClient
Function MatchingFormElements()
	
	// To fix translation errors
	CatalogFormElements = New Map();
	
	ItemArray = New Array();
	ItemArray.Add(SuccessfulTypesOfItems);
	ItemArray.Add(Items.ReplaceItemTypes);
	ItemArray.Add(Items.GroupTheTypesOfItems);
	ItemArray.Add(Items.TheseTypesOfItems);
	ItemArray.Add(Items.DecorationBidReplacementItemTypes);
	ItemArray.Add(Items.DecorationBidReplacementSuccessfullyItemTypes);
	
	CatalogFormElements.Insert("ItemKinds", ItemArray);
	
	ItemArray = New Array();
	ItemArray.Add(SuccessfulItem);
	ItemArray.Add(Items.ReplaceItem);
	ItemArray.Add(Items.NomenclatureGroup);
	ItemArray.Add(Items.DataItem);
	ItemArray.Add(Items.DecorationBidReplacementItem);
	ItemArray.Add(Items.DecorationBidReplacementSuccessfulItem);
	
	CatalogFormElements.Insert("Products", ItemArray);
	
	ItemArray = New Array();
	ItemArray.Add(SuccessfullyContractingContractsOfCounterparties);
	ItemArray.Add(Items.ReplaceContractsOfCounterparties);
	ItemArray.Add(Items.GroupOfContractsOfCounterparties);
	ItemArray.Add(Items.DataContractsOfCounterparties);
	ItemArray.Add(Items.DecorationBidReplacementContractsOfCounterparties);
	ItemArray.Add(Items.DecorationBidReplacementSuccessfullyContractsOfCounterparties);
	
	CatalogFormElements.Insert("CounterpartyContracts", ItemArray);
	
	ItemArray = New Array();
	ItemArray.Add(SuccessfulContractsBetweenOrganizations);
	ItemArray.Add(Items.ReplaceContractsBetweenOrganizations);
	ItemArray.Add(Items.GroupContractsBetweenOrganizations);
	ItemArray.Add(Items.TheseContractsBetweenOrganizations);
	ItemArray.Add(Items.DecorationBidReplacementContractsBetweenOrganizations);
	ItemArray.Add(Items.DecorationBidReplacementSuccessfulContractsBetweenOrganizations);
	
	CatalogFormElements.Insert("IntercompanyContracts", ItemArray);
	
	ItemArray = New Array();
	ItemArray.Add(SuccessfulLeaseContracts);
	ItemArray.Add(Undefined);
	ItemArray.Add(Items.GroupLeaseContracts);
	ItemArray.Add(Items.TheseLeaseContracts);
	ItemArray.Add(Items.DecorationReplacementOfRatesRentalContracts);
	ItemArray.Add(Items.DecorationReplacementOfBidsSuccessfullyLeaseContracts);
	
	CatalogFormElements.Insert("LeaseContract", ItemArray);
		
	Return CatalogFormElements;
	
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
	If Item.Name = "sh_ShamsiInput_F_Period" Then
		PeriodOnChange(Items.Period);
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
