
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ThisIsASalesDocument           = ?(Parameters.Property("ThisIsASalesDocument"),Parameters.ThisIsASalesDocument,False);
	ThisIsAPurchaseDocument           = ?(Parameters.Property("ThisIsAPurchaseDocument"),Parameters.ThisIsAPurchaseDocument,False);
	DocumentDate                = Parameters.DocumentDate;
	DocumentCurrency              = Parameters.DocumentCurrency;
	DocumentAmount               = Parameters.DocumentAmount;
	TheAmountOfTheDocumentWhenOpened    = Parameters.DocumentAmount;
	CurrencyOfTheDocumentWhenOpened   = Parameters.DocumentCurrency;
	Organization                  = Parameters.Organization;
	ContractRateOption         = Parameters.ContractRateOption;
	Contract                      = Parameters.Contract;
	DocumentExchangeRateDate     = Parameters.DocumentExchangeRateDate;
	ThereIsDateOfDocumentSCurrencyExchangeRate = Parameters.ThereIsDateOfDocumentSCurrencyExchangeRate;
	ComplAccountingCurrency               = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	CurrencyOfManAccounting               = SettingsValueCached.ManagementAccountingCurrency();
	DocumentCurrencyChangeControl = CurrencyOfTheDocumentWhenOpened;
	
	ReflectExchangeRateOnDate = ValueIsFilled(DocumentExchangeRateDate);
	
	ARAPCurrency            = Parameters.ARAPCurrency;
	CurrencyOfMutualSettlementsAtOpening = Parameters.ARAPCurrency;
	
	ReadOnly                     = Parameters.ReadOnly;
	DocumentCurrencyViewOnly      = Parameters.Property("DocumentCurrencyViewOnly") 
											And Parameters.DocumentCurrencyViewOnly;
	DocumentAmountViewOnly       = Parameters.Property("DocumentAmountViewOnly") 
											And Parameters.DocumentAmountViewOnly;
	
	MutualSettlementsCurrencyViewOnly = Parameters.Property("MutualSettlementsCurrencyViewOnly")
											And Parameters.MutualSettlementsCurrencyViewOnly;
	
	DonTShowCalculations                = Parameters.Property("DonTShowCalculations") 
											And Parameters.DonTShowCalculations;
	
	DoNotRecalculateTheAmountOfTheDocument      = Parameters.Property("DoNotRecalculateTheAmountOfTheDocument") 
											And Parameters.DoNotRecalculateTheAmountOfTheDocument;
	
	BasicCourseAccuracy = Metadata.DefinedTypes.CurrencyExchangeRate.Type.NumberQualifiers.FractionDigits;
	
	If ARAPCurrency = DocumentCurrency And Parameters.AmountARAP = 0 Then
		AmountARAP = Parameters.DocumentAmount;
	Else
		AmountARAP = Parameters.AmountARAP;
	EndIf;
	
	If DocumentCurrency = ComplAccountingCurrency And Not ARAPCurrency = ComplAccountingCurrency Then
		NumeratorOfSettlementCurrency = Parameters.CourseNumerator;
		DenominatorOfSettlementCurrency = Parameters.CourseDenominator;
		NumeratorOfDocumentCurrency = 1;
		DenominatorOfDocumentCurrency = 1;
	Else
		NumeratorOfDocumentCurrency = Parameters.CourseNumerator;
		DenominatorOfDocumentCurrency = Parameters.CourseDenominator;
		NumeratorOfSettlementCurrency = 1;
		DenominatorOfSettlementCurrency = 1;
	EndIf;
	
	FillInNumeratorDenominatorLabels();
	
	SetItemsVisibility();
	
	FillInListOfExchangeRates();
	
	SetCourseAccuracy();
	
	SetTextColorOfFieldsAtServer("", True);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Exit Then
		
		StandardProcessing = False;
		
		If Modified And Not Done Then
			
			Cancel = True;
			
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
				New CallbackDescription("BeforeCloseCompletion", ThisObject), 
				NStr("vi = 'Tất cả dữ liệu đã thay đổi sẽ bị mất. Đóng biểu mẫu?';
					|ru = 'Все измененные данные будут потеряны. Закрыть форму?';
					|en = 'All changed data will be lost. Close the form?'; fa = 'All changed data will be lost. Close the form?';
					|it = 'Tutti i dati modificati andranno persi. Chiudere il form?';
					|pl = 'Wszystkie zmodyfikowane dane zostaną utracone. Chcesz zamknąć formularz?';
					|tr = 'Tüm değişiklikler kaybolacak. Kapatılsın mı?'"), 
				ButtonsList);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = "Close" Then
		Modified = False;
		Close();
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DocumentAmountFieldOnChange(Item)
	RecalculateDocumentAmounts = DocumentAmount <> TheAmountOfTheDocumentWhenOpened;
	SetTextColorOfFields(Item.Name, True);
EndProcedure

&AtClient
Procedure NumeratorOfSettlementCurrencyChoiceProcessing(Item, ValueSelected, AdditionalData, ChoiceByAdding, StandardProcessing)
	ProcessingSelectionOfSettlementCurrencyFields(ValueSelected, StandardProcessing);
EndProcedure

&AtClient
Procedure DenominatorOfSettlementCurrencyChoiceProcessing(Item, ValueSelected, AdditionalData, ChoiceByAdding, StandardProcessing)
	ProcessingSelectionOfSettlementCurrencyFields(ValueSelected, StandardProcessing);
EndProcedure

&AtClient
Procedure NumeratorOfSettlementCurrencyOnChange(Item)
	If DocumentAmountViewOnly Then
		RecalculateAmountOfSettlementsAtServer();
	Else
		SetTextColorOfFields(Item.Name, True);
	EndIf;
EndProcedure

&AtClient
Procedure DenominatorOfSettlementCurrencyOnChange(Item)
	If DocumentAmountViewOnly Then
		RecalculateAmountOfSettlementsAtServer();
	Else
		SetTextColorOfFields(Item.Name, True);
	EndIf;
EndProcedure

&AtClient
Procedure ProcessingSelectionOfSettlementCurrencyFields(ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueSelected = 0 Then
		OnCloseNotifyHandler = New CallbackDescription("ExchangeRateOfSettlementsProcessingSelectionCompletion", ThisObject);
		ShowInputDate(OnCloseNotifyHandler, DocumentDate, NStr("vi = 'Hãy chỉ ra ngày của tỷ giá hối đoái';
																|ru = 'Укажите дату курса валюты';
																|en = 'Specify the exchange rate date'; fa = 'Specify the exchange rate date';
																|it = 'Indicare la data del tasso di cambio';
																|pl = 'Wskaż datę kursu waluty';
																|tr = 'Döviz kuru tarihi seç'"), DateFractions.Date);
	Else
		NumeratorOfSettlementCurrency = ValueSelected.CourseNumerator;
		DenominatorOfSettlementCurrency = ValueSelected.CourseDenominator;
		ClearMessages();
		If DocumentAmountViewOnly Then
			RecalculateAmountOfSettlementsAtServer();
		Else
			SetTextColorOfFields(Items.NumeratorOfSettlementCurrency.Name, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExchangeRateOfSettlementsProcessingSelectionCompletion(DateOfCourse, AdditionalParameters) Export
	
	If DateOfCourse <> Undefined Then
		ExchangeRateOfSettlementsProcessingSelectionOnServer(DateOfCourse);
	EndIf;
	
EndProcedure

&AtClient
Procedure NumeratorOfDocumentCurrencyChoiceProcessing(Item, ValueSelected, AdditionalData, ChoiceByAdding, StandardProcessing)
	ProcessingSelectionOfDocumentCurrencyFields(ValueSelected, StandardProcessing);
EndProcedure

&AtClient
Procedure NumeratorOfDocumentCurrencyOnChange(Item)
	If DocumentAmountViewOnly Then
		RecalculateAmountOfSettlementsAtServer();
	Else
		SetTextColorOfFields(Item.Name, True);
	EndIf;
EndProcedure

&AtClient
Procedure DenominatorOfDocumentCurrencyChoiceProcessing(Item, ValueSelected, AdditionalData, ChoiceByAdding, StandardProcessing)
	ProcessingSelectionOfDocumentCurrencyFields(ValueSelected, StandardProcessing);
EndProcedure

&AtClient
Procedure DenominatorOfDocumentCurrencyOnChange(Item)
	If DocumentAmountViewOnly Then
		RecalculateAmountOfSettlementsAtServer();
	Else
		SetTextColorOfFields(Item.Name, True);
	EndIf;
EndProcedure

&AtClient
Procedure ProcessingSelectionOfDocumentCurrencyFields(ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueSelected = 0 Then
		OnCloseNotifyHandler = New CallbackDescription("DocumentCourseProcessingSelectionCompletion", ThisObject);
		ShowInputDate(OnCloseNotifyHandler, DocumentDate, NStr("vi = 'Hãy chỉ ra ngày của tỷ giá hối đoái';
																|ru = 'Укажите дату курса валюты';
																|en = 'Specify the exchange rate date'; fa = 'Specify the exchange rate date';
																|it = 'Indicare la data del tasso di cambio';
																|pl = 'Wskaż datę kursu waluty';
																|tr = 'Döviz kuru tarihi seç'"), DateFractions.Date);
	Else
		NumeratorOfDocumentCurrency = ValueSelected.CourseNumerator;
		DenominatorOfDocumentCurrency = ValueSelected.CourseDenominator;
		ClearMessages();
		If DocumentAmountViewOnly Then
			RecalculateAmountOfSettlementsAtServer();
		ElsIf ARAPCurrency <> ComplAccountingCurrency 
			And DocumentCurrency = ComplAccountingCurrency Then
			SetTextColorOfFields(Items.NumeratorOfSettlementCurrency.Name, True);
		Else
			SetTextColorOfFields(Items.NumeratorOfDocumentCurrency.Name, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure DocumentCourseProcessingSelectionCompletion(DateOfCourse, AdditionalParameters) Export
	
	If DateOfCourse <> Undefined Then
		CourseOfDocumentProcessingSelectionOnServer(DateOfCourse);
	EndIf;
	
EndProcedure

&AtClient
Procedure ARAPCurrencyOnChange(Item)
	
	If Not ValueIsFilled(ARAPCurrency) Then
		ARAPCurrency = CurrencyOfMutualSettlementsAtOpening;
	EndIf;
	
	If ARAPCurrency = ComplAccountingCurrency Then
		NumeratorOfSettlementCurrency = 1;
		DenominatorOfSettlementCurrency = 1;
	EndIf;
	
	UpdateDisplay(True);
	If Not DocumentAmountViewOnly Then
		SetTextColorOfFields(Item.Name, True);
	EndIf;
	If ARAPCurrency = DocumentCurrency Then
		AmountARAP = DocumentAmount;
		SetTextColorOfFields();
	EndIf;
	
	If Not VisibilityOfDateOfDocumentSCurrencyExchangeRate(ThereIsDateOfDocumentSCurrencyExchangeRate, ContractRateOption, 
	                                          DocumentCurrency, ARAPCurrency, 
	                                          ComplAccountingCurrency, CurrencyOfManAccounting) Then
		ReflectExchangeRateOnDate = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure DocumentCurrencyOnChange(Item)
	
	If Not ValueIsFilled(CurrencyOfTheDocumentWhenOpened)
		Or DoNotRecalculateTheAmountOfTheDocument
		Or DocumentCurrencyChangeControl = DocumentCurrency Then
		Return;
	EndIf;
	DocumentCurrencyChangeControl = DocumentCurrency;
	
	If DocumentAmount = 0 Then
		
		RecalculateAmountWhenChangingCurrency(DialogReturnCode.Yes, Undefined);
		
	ElsIf CurrencyOfTheDocumentWhenOpened <> DocumentCurrency And ValueIsFilled(DocumentCurrency) Then
		MessageText = NStr("ru = 'Изменена валюта документа, какую сумму необходимо пересчитать по курсу?';
							|vi = 'The document currency is changed. What amount must be recalculated at the rate?';
							|en = 'The document currency is changed. What amount must be recalculated at the rate?'; fa = 'The document currency is changed. What amount must be recalculated at the rate?';
							|it = 'The document currency is changed. What amount must be recalculated at the rate?';
							|pl = 'The document currency is changed. What amount must be recalculated at the rate?';
							|tr = 'Belge para birimi değiştirildi, hangi tutarın kur üzerinden yeniden hesaplanması gerekiyor?'");
		
		DialogButtons = New ValueList;
		DialogButtons.Add(DialogReturnCode.Yes, NStr("ru = 'Сумма документа';
													|vi = 'Document amount';
													|en = 'Document amount'; fa = 'مبلغ سند';
													|it = 'Importo del documento';
													|pl = 'Wartość dokumentu';
													|tr = 'Belge tutarı'"));
		DialogButtons.Add(DialogReturnCode.No, NStr("ru = 'Сумма взаиморасчетов';
													|vi = 'AR/AP amount';
													|en = 'AR/AP amount'; fa = 'مبلغ دریافتنی/پرداختنی';
													|it = 'Importo dei pagamenti reciproci';
													|pl = 'Wartość rozliczeń wzajemnych';
													|tr = 'Borç-alacak muhasebesi tutarı'"));
		Notification = New CallbackDescription("RecalculateAmountWhenChangingCurrency", ThisObject);
		ShowQueryBox(Notification, MessageText, DialogButtons);
		
	Else
		
		If DocumentCurrency = ComplAccountingCurrency Or ARAPCurrency = DocumentCurrency Then
			NumeratorOfDocumentCurrency = 1;
			DenominatorOfDocumentCurrency = 1;
		EndIf;
		
		DocumentCurrency = CurrencyOfTheDocumentWhenOpened;
		DocumentAmount = TheAmountOfTheDocumentWhenOpened;
		DocumentCurrencyChangeControl = DocumentCurrency;
		
		UpdateDisplay(True);
		RecalculateMutualSettlementsAmount(Undefined);
	EndIf;
	
	If Not VisibilityOfDateOfDocumentSCurrencyExchangeRate(ThereIsDateOfDocumentSCurrencyExchangeRate, ContractRateOption, 
	                                          DocumentCurrency, ARAPCurrency, 
	                                          ComplAccountingCurrency, CurrencyOfManAccounting) Then
		ReflectExchangeRateOnDate = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure RecalculateAmountWhenChangingCurrency(UserAnswer, AdditionalParameters) Export
	
	UpdateDisplay(True);
	If UserAnswer = DialogReturnCode.Yes Then
		RecalculateTheDocumentAmount(Undefined);
	EndIf;
	
	ClearMessages();
	
	If DocumentCurrency = ComplAccountingCurrency Or DocumentCurrency = ARAPCurrency Then
		NumeratorOfDocumentCurrency = 1;
		DenominatorOfDocumentCurrency = 1;
	EndIf;
	
	RecalculateMutualSettlementsAmount(Undefined);
	
EndProcedure

&AtClient
Procedure ReflectExchangeRateOnDateOnChange(Item)
	If Not ReflectExchangeRateOnDate Then
		DocumentExchangeRateDate = Date(1,1,1);
	EndIf;
EndProcedure

&AtClient
Procedure DocumentExchangeRateDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	If ValueIsFilled(DocumentExchangeRateDate) Then
		ReflectExchangeRateOnDate = True;
		DateOfDocumentCurrencyExchangeRateWhenChangedOnServer();
	EndIf;
EndProcedure

&AtClient
Procedure ContractRateOptionClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	OpeningParameters = New Structure("Filter", New Structure("Contract", Contract));
	OpenForm("InformationRegister.ARAPAccountingExchangeRatesForContracts.Form.ByContractListForm", OpeningParameters);
	
EndProcedure

&AtClient
Procedure AmountARAPOnChange(Item)
	
	If DocumentAmountViewOnly Then
		If DocumentCurrency <> ComplAccountingCurrency
			And ARAPCurrency <> ComplAccountingCurrency Then
			Accuracy = 8;
		Else
			Accuracy = BasicCourseAccuracy;
		EndIf;
		
		If Not ValueIsFilled(DocumentCurrency) Then
			NumeratorOfDocumentCurrency = 1;
		ElsIf Not DocumentCurrency = ComplAccountingCurrency And ARAPCurrency = ComplAccountingCurrency Then
			NumeratorOfDocumentCurrency = Round(AmountARAP / DocumentAmount * DenominatorOfDocumentCurrency, Accuracy);
		ElsIf Not ARAPCurrency = ComplAccountingCurrency And DocumentCurrency = ComplAccountingCurrency Then
			NumeratorOfSettlementCurrency = ?(AmountARAP=0, 0, Round(DocumentAmount * DenominatorOfSettlementCurrency / AmountARAP, BasicCourseAccuracy));
		Else
			NumeratorOfDocumentCurrency = Round(AmountARAP / DocumentAmount * DenominatorOfDocumentCurrency, Accuracy);
		EndIf;
	Else
		SetTextColorOfFields(Item.Name, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	If ThereAreMismatches Then
		
		BasicFormatString = StrTemplate("NFD=%1", BasicCourseAccuracy);
		
		If DocumentCurrency = ComplAccountingCurrency Then
			If DenominatorOfSettlementCurrency = 1 Then
				Rate = Format(NumeratorOfSettlementCurrency, BasicFormatString);
			ElsIf Int(DenominatorOfSettlementCurrency) = DenominatorOfSettlementCurrency Then
				Rate = StrTemplate("%1/%2", Format(NumeratorOfSettlementCurrency, BasicFormatString), Format(DenominatorOfSettlementCurrency, "NFD=0"));
			Else
				Rate = StrTemplate("%1/%2", Format(NumeratorOfSettlementCurrency, BasicFormatString), Format(DenominatorOfSettlementCurrency, BasicFormatString));
			EndIf;
		ElsIf ARAPCurrency = ComplAccountingCurrency Then
			If DenominatorOfDocumentCurrency = 1 Then
				Rate = Format(NumeratorOfDocumentCurrency, BasicFormatString);
			ElsIf Int(DenominatorOfDocumentCurrency) = DenominatorOfDocumentCurrency Then
				Rate = StrTemplate("%1/%2", Format(NumeratorOfDocumentCurrency, BasicFormatString), Format(DenominatorOfDocumentCurrency, "NFD=0"));
			Else
				Rate = StrTemplate("%1/%2", Format(NumeratorOfDocumentCurrency, BasicFormatString), Format(DenominatorOfDocumentCurrency, BasicFormatString));
			EndIf;
		Else
			If DenominatorOfDocumentCurrency = 1 Then
				Rate = Format(NumeratorOfDocumentCurrency, "NFD=8");
			ElsIf Int(DenominatorOfDocumentCurrency) = DenominatorOfDocumentCurrency Then
				Rate = StrTemplate("%1/%2", Format(NumeratorOfDocumentCurrency, "NFD=8"), Format(DenominatorOfDocumentCurrency, "NFD=0"));
			Else
				Rate = StrTemplate("%1/%2", Format(NumeratorOfDocumentCurrency, "NFD=8"), Format(DenominatorOfDocumentCurrency, "NFD=8"));
			EndIf;
		EndIf;
		
		MessageText = StrTemplate(NStr("ru = 'Сумма взаиморасчетов %1 по курсу %2 не соответствует сумме документа %3.
		                                      |Продолжить?';
		                                      |vi = 'The AR/AP amount (%1) at the %2 rate does not correspond to the document amount (%3).
		                                      |Continue?';
		                                      |en = 'The AR/AP amount (%1) at the %2 rate does not correspond to the document amount (%3).
		                                      |Continue?'; fa = 'The AR/AP amount (%1) at the %2 rate does not correspond to the document amount (%3).
		                                      |Continue?';
		                                      |it = 'The AR/AP amount (%1) at the %2 rate does not correspond to the document amount (%3).
		                                      |Continue?';
		                                      |pl = 'The AR/AP amount (%1) at the %2 rate does not correspond to the document amount (%3).
		                                      |Continue?';
		                                      |tr = 'Karşılıklı hesaplaşma tutarı %1  %2 kur üzerinden belge tutarı %3 ile uyuşmuyor. 
		                                      |Devam edilsin mi?'"),
		                           Format(AmountARAP, "NFD=2"),
		                           Rate,
		                           Format(DocumentAmount, "NFD=2"));
		
		ShowQueryBox(
			New CallbackDescription("MoveToDocumentCompletion", ThisObject), 
			MessageText,
			QuestionDialogMode.YesNo);
		
	Else
		
		MoveToDocumentCompletion("", Undefined);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure MoveToDocumentCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.No Then
		Return;
	EndIf;
	
	StructureOfFormDetails = New Structure;
	StructureOfFormDetails.Insert("ARAPCurrency", ARAPCurrency);
	StructureOfFormDetails.Insert("Currency",               DocumentCurrency);
	
	If Not ARAPCurrency = ComplAccountingCurrency And DocumentCurrency = ComplAccountingCurrency Then
		StructureOfFormDetails.Insert("CourseNumerator",   NumeratorOfSettlementCurrency);
		StructureOfFormDetails.Insert("CourseDenominator", DenominatorOfSettlementCurrency);
	Else
		StructureOfFormDetails.Insert("CourseNumerator",   NumeratorOfDocumentCurrency);
		StructureOfFormDetails.Insert("CourseDenominator", DenominatorOfDocumentCurrency);
	EndIf;
	
	If ReflectExchangeRateOnDate
		And VisibilityOfDateOfDocumentSCurrencyExchangeRate(ThereIsDateOfDocumentSCurrencyExchangeRate, ContractRateOption, 
		                                    DocumentCurrency, ARAPCurrency, 
		                                    ComplAccountingCurrency, CurrencyOfManAccounting) Then
		StructureOfFormDetails.Insert("DocumentExchangeRateDate", DocumentExchangeRateDate)
	Else
		StructureOfFormDetails.Insert("DocumentExchangeRateDate", Date(1,1,1));
	EndIf;
	
	StructureOfFormDetails.Insert("AmountARAP", AmountARAP);
	StructureOfFormDetails.Insert("DocumentAmount", DocumentAmount);
	
	RecalculationIsRequired = DocumentAmount <> 0 And ValueIsFilled(CurrencyOfTheDocumentWhenOpened);
	
	StructureOfFormDetails.Insert("RecalculateDocumentAmounts", RecalculateDocumentAmounts And RecalculationIsRequired);
	
	Done = True;
	
	Close(StructureOfFormDetails);
	
EndProcedure

&AtServer
Procedure FillInListOfExchangeRates(CurrencyChanged_=False)
	
	ListOfExchangeRates = New ValueList;
	ArrayOfDaysForSelectionList = New Array;
	If ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract Then
		ArrayOfDaysForSelectionList = GetDatesOfContractCurrencyExchangeRate();
	Else
		For DayMinus = 1 To 5 Do
			DateOfCourse = DocumentDate - (DayMinus * 86400);
			ArrayOfDaysForSelectionList.Add(DateOfCourse);
		EndDo;
	EndIf; 
	
	DateForRate = ?(ReflectExchangeRateOnDate, DocumentExchangeRateDate, DocumentDate);
	
	If DocumentCurrency = ComplAccountingCurrency 
		Or ARAPCurrency = ComplAccountingCurrency Then
		
		If Not DocumentCurrency = ComplAccountingCurrency Then
			CourseAsOfDate = GetCurrencyRate(DocumentCurrency, DateForRate, ComplAccountingCurrency);
			If Not ValueIsFilled(NumeratorOfDocumentCurrency) Or CurrencyChanged_ Then
				DenominatorOfDocumentCurrency = CourseAsOfDate.CourseDenominator;
				NumeratorOfDocumentCurrency = CourseAsOfDate.CourseNumerator;
			EndIf;
			
			AddCourseToChoiceList(DocumentCurrency, DateForRate, ComplAccountingCurrency, ListOfExchangeRates, CourseAsOfDate);
			
			For Each DateOfCourse In ArrayOfDaysForSelectionList Do
				
				AddCourseToChoiceList(DocumentCurrency, DateOfCourse, ComplAccountingCurrency, ListOfExchangeRates);
					
			EndDo;
			ListOfExchangeRates.Add(0, NStr("vi = '<Chọn ngày khác>';
											|ru = '<Выбрать другую дату>';
											|en = '<Select another date>'; fa = '<Select another date>';
											|it = '<selezionare un''altra data>';
											|pl = '<Wybierz inną datę>';
											|tr = '<Başka bir tarih seç>'"));  
			
			If DateForRate <> DocumentDate 
				And ArrayOfDaysForSelectionList.Find(DocumentDate) = Undefined Then
			
				AddCourseToChoiceList(DocumentCurrency, DocumentDate, ComplAccountingCurrency, ListOfExchangeRates);
			
			EndIf;
			
			Items.NumeratorOfDocumentCurrency.ChoiceList.Clear();
			Items.DenominatorOfDocumentCurrency.ChoiceList.Clear();
			
			For Each CourseAsOfDate In ListOfExchangeRates Do
				Items.NumeratorOfDocumentCurrency.ChoiceList.Add(CourseAsOfDate.Value, CourseAsOfDate.Presentation);
				Items.DenominatorOfDocumentCurrency.ChoiceList.Add(CourseAsOfDate.Value, CourseAsOfDate.Presentation);
			EndDo;
		Else
			CourseAsOfDate = GetCurrencyRate(ARAPCurrency, DateForRate, ComplAccountingCurrency);
			If Not ValueIsFilled(NumeratorOfSettlementCurrency) Or CurrencyChanged_ Then
				NumeratorOfSettlementCurrency = CourseAsOfDate.CourseNumerator;
				DenominatorOfSettlementCurrency = CourseAsOfDate.CourseDenominator;
			EndIf;
			
			AddCourseToChoiceList(ARAPCurrency, DateForRate, ComplAccountingCurrency, ListOfExchangeRates, CourseAsOfDate);
				
			For Each DateOfCourse In ArrayOfDaysForSelectionList Do
				
				AddCourseToChoiceList(ARAPCurrency, DateOfCourse, ComplAccountingCurrency, ListOfExchangeRates);
				
			EndDo;
			ListOfExchangeRates.Add(0, NStr("vi = '<Chọn ngày khác>';
											|ru = '<Выбрать другую дату>';
											|en = '<Select another date>'; fa = '<Select another date>';
											|it = '<selezionare un''altra data>';
											|pl = '<Wybierz inną datę>';
											|tr = '<Başka bir tarih seç>'"));
			
			If DateForRate <> DocumentDate 
				And ArrayOfDaysForSelectionList.Find(DocumentDate) = Undefined Then
				
				AddCourseToChoiceList(ARAPCurrency, DocumentDate, ComplAccountingCurrency, ListOfExchangeRates);
				
			EndIf;
			
			Items.NumeratorOfSettlementCurrency.ChoiceList.Clear();
			Items.DenominatorOfSettlementCurrency.ChoiceList.Clear();
			
			For Each CourseAsOfDate In ListOfExchangeRates Do
				Items.NumeratorOfSettlementCurrency.ChoiceList.Add(CourseAsOfDate.Value, CourseAsOfDate.Presentation);
				Items.DenominatorOfSettlementCurrency.ChoiceList.Add(CourseAsOfDate.Value, CourseAsOfDate.Presentation);
			EndDo;
		EndIf;
		
	ElsIf ValueIsFilled(DocumentCurrency) And ValueIsFilled(ARAPCurrency) Then
		
		DocumentCurrencyRateAsOfDate = GetCurrencyRate(DocumentCurrency, DateForRate, ComplAccountingCurrency);
		ExchangeRateOfSettlementsAsOfDate = GetCurrencyRate(ARAPCurrency, DateForRate, ComplAccountingCurrency);
		
		ConversionRate_1 = ProcessingOfExchangeRatesTM.GetCrossCurrencyExchangeRate(DocumentCurrencyRateAsOfDate, ExchangeRateOfSettlementsAsOfDate, 8);
		If Not ValueIsFilled(NumeratorOfDocumentCurrency) Or CurrencyChanged_ Then
			DenominatorOfDocumentCurrency = ConversionRate_1.CourseDenominator;
			NumeratorOfDocumentCurrency = ConversionRate_1.CourseNumerator;
		EndIf;
		
		AddCourseToChoiceList(DocumentCurrency, DateForRate, ARAPCurrency, ListOfExchangeRates, ConversionRate_1);
		
		For Each DateOfCourse In ArrayOfDaysForSelectionList Do
				
			DocumentCurrencyRateAsOfDate = GetCurrencyRate(DocumentCurrency, DateOfCourse, ComplAccountingCurrency);
			ExchangeRateOfSettlementsAsOfDate = GetCurrencyRate(ARAPCurrency, DateOfCourse, ComplAccountingCurrency);
			ConversionRate_1 = ProcessingOfExchangeRatesTM.GetCrossCurrencyExchangeRate(DocumentCurrencyRateAsOfDate, ExchangeRateOfSettlementsAsOfDate, 8);
			AddCourseToChoiceList(DocumentCurrency, DateOfCourse, ARAPCurrency, ListOfExchangeRates, ConversionRate_1);
		EndDo;
		ListOfExchangeRates.Add(0, NStr("vi = '<Chọn ngày khác>';
										|ru = '<Выбрать другую дату>';
										|en = '<Select another date>'; fa = '<Select another date>';
										|it = '<selezionare un''altra data>';
										|pl = '<Wybierz inną datę>';
										|tr = '<Başka bir tarih seç>'"));
		
		If DateForRate <> DocumentDate 
			And ArrayOfDaysForSelectionList.Find(DocumentDate) = Undefined Then
		
			DocumentCurrencyRateAsOfDate = GetCurrencyRate(DocumentCurrency, DocumentDate, ComplAccountingCurrency);
			ExchangeRateOfSettlementsAsOfDate = GetCurrencyRate(ARAPCurrency, DocumentDate, ComplAccountingCurrency);
			ConversionRate_1 = ProcessingOfExchangeRatesTM.GetCrossCurrencyExchangeRate(DocumentCurrencyRateAsOfDate, ExchangeRateOfSettlementsAsOfDate, 8);
			AddCourseToChoiceList(DocumentCurrency, DocumentDate, ARAPCurrency, ListOfExchangeRates, ConversionRate_1);
		
		EndIf;
		
		Items.NumeratorOfDocumentCurrency.ChoiceList.Clear();
		Items.DenominatorOfDocumentCurrency.ChoiceList.Clear();
		
		For Each CourseAsOfDate In ListOfExchangeRates Do
			Items.NumeratorOfDocumentCurrency.ChoiceList.Add(CourseAsOfDate.Value, CourseAsOfDate.Presentation);
			Items.DenominatorOfDocumentCurrency.ChoiceList.Add(CourseAsOfDate.Value, CourseAsOfDate.Presentation);
		EndDo;
		
	EndIf;
	
	BasicFormatString = StrTemplate("NFD=%1", BasicCourseAccuracy);
	If DocumentCurrency = ComplAccountingCurrency 
		Or ARAPCurrency = ComplAccountingCurrency Then
		CourseFormat = BasicFormatString;
	Else
		CourseFormat = "NFD=8";
	EndIf;
	
	If Items.NumeratorOfDocumentCurrency.ChoiceList.Count()>0
		And ValueIsFilled(NumeratorOfDocumentCurrency) Then
		
		If Not CourseIsOnList(Items.NumeratorOfDocumentCurrency.ChoiceList, NumeratorOfDocumentCurrency, DenominatorOfDocumentCurrency) Then
			
			Presentation = Format(NumeratorOfDocumentCurrency, CourseFormat) + " " + ARAPCurrency + " = " +
				Format(DenominatorOfDocumentCurrency, BasicFormatString) + " " + DocumentCurrency;
				
			Structure = New Structure("CourseNumerator, CourseDenominator", NumeratorOfDocumentCurrency, DenominatorOfDocumentCurrency);
			Items.NumeratorOfDocumentCurrency.ChoiceList.Add(Structure, Presentation);
			Items.DenominatorOfDocumentCurrency.ChoiceList.Add(Structure, Presentation);
			
		EndIf;
	EndIf;
	
	If Items.NumeratorOfSettlementCurrency.ChoiceList.Count()>0 
		And ValueIsFilled(NumeratorOfSettlementCurrency) Then
			
		If Not CourseIsOnList(Items.NumeratorOfSettlementCurrency.ChoiceList, NumeratorOfSettlementCurrency, DenominatorOfSettlementCurrency) Then

			Presentation = Format(NumeratorOfSettlementCurrency, CourseFormat) + " " + DocumentCurrency + " = " +
				Format(DenominatorOfSettlementCurrency, BasicFormatString) + " " + ARAPCurrency;
				
			Structure = New Structure("CourseNumerator, CourseDenominator", NumeratorOfSettlementCurrency, DenominatorOfSettlementCurrency); 
			Items.NumeratorOfSettlementCurrency.ChoiceList.Add(Structure, Presentation);
			Items.DenominatorOfSettlementCurrency.ChoiceList.Add(Structure, Presentation);
		
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function GetCurrencyRate(Currency, Date, BaseCurrency)
	
	If ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract 
		And Currency = ARAPCurrency
		And ARAPCurrency = CurrencyOfMutualSettlementsAtOpening Then
		
		Result = InformationRegisters.ARAPAccountingExchangeRatesForContracts.GetContractCurrencyExchangeRateValues(Contract, Date);
		Result.Insert("Currency",    Currency);
		Result.Insert("BaseCurrency", BaseCurrency);
		If Result.Property("CourseIsNotSet") And Result.CourseIsNotSet Then
			Result = ProcessingOfExchangeRatesTM.GetCurrencyRate(Currency, Date, BaseCurrency)
		EndIf;
		
	Else
		
		Result = ProcessingOfExchangeRatesTM.GetCurrencyRate(Currency, Date, BaseCurrency)
		
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  Currency - CatalogRef.Currencies
//  Date - Date
//  BaseCurrency  - CatalogRef.Currencies
//  ChoiceList - ValueList of Structure
//  RateStructure - See ProcessingOfExchangeRatesTM.GetCurrencyRate 
&AtServer
Procedure AddCourseToChoiceList(Currency, Date, BaseCurrency, ChoiceList, RateStructure = Undefined)
	
	If RateStructure = Undefined Then
		RateStructure = GetCurrencyRate(Currency, Date, BaseCurrency);
	EndIf;
	
	BasicFormatString = StrTemplate("NFD=%1", BasicCourseAccuracy);
	If DocumentCurrency = ComplAccountingCurrency
		Or ARAPCurrency = ComplAccountingCurrency Then
		NumeratorFormat = BasicFormatString;
	Else
		NumeratorFormat = "NFD=8";
	EndIf;
	
	Structure = New Structure("CourseNumerator, CourseDenominator", RateStructure.CourseNumerator, RateStructure.CourseDenominator); 
	ChoiceList.Add(Structure, Format(RateStructure.CourseNumerator, NumeratorFormat) +" " + BaseCurrency + " = " + Format(RateStructure.CourseDenominator, BasicFormatString) +
		" " + Currency + " " + StrTemplate(NStr("vi = '(%1)';
												|ru = '(на %1)';
												|en = '(as of %1)'; fa = '(as of %1)';
												|it = '(in %1)';
												|pl = '(na %1)';
												|tr = '(%1 tarihinde)'"), Format(Date, "DLF = D")));
	
EndProcedure

&AtServer
Function GetDatesOfContractCurrencyExchangeRate()
	Query = New Query;
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("DocumentDate", DocumentDate);
	Query.Text = 
		"SELECT TOP 5
		|	ARAPAccountingExchangeRatesForContracts.Period AS Period
		|FROM
		|	InformationRegister.ARAPAccountingExchangeRatesForContracts AS ARAPAccountingExchangeRatesForContracts
		|WHERE
		|	ARAPAccountingExchangeRatesForContracts.Contract = &Contract
		|	AND ARAPAccountingExchangeRatesForContracts.Period < &DocumentDate
		|	AND ARAPAccountingExchangeRatesForContracts.Period > DATETIME(1980, 1, 1)
		|
		|ORDER BY
		|	Period DESC";
	
	Return Query.Execute().Unload().UnloadColumn("Period");
	
EndFunction

&AtServer
Procedure ExchangeRateOfSettlementsProcessingSelectionOnServer(DateOfCourse)
	
	If Not DateOfCourse > CurrentSessionDate() Then
		DateText_1 = " " + StrTemplate(NStr("vi = '(cho %1)';
											|ru = '(на %1)';
											|en = '(by %1)'; fa = '(by %1)';
											|it = '(in %1)';
											|pl = '(na %1)';
											|tr = '(%1 tarihinde)'"), Format(DateOfCourse, "DLF = D"));
	Else
		DateText_1 = "";
	EndIf;
	
	CourseAsOfDate = GetCurrencyRate(ARAPCurrency, DateOfCourse, ComplAccountingCurrency);
	NumeratorOfSettlementCurrency = CourseAsOfDate.CourseNumerator;
	DenominatorOfSettlementCurrency = CourseAsOfDate.CourseDenominator;
	
	BasicFormatString = StrTemplate("NFD=%1", BasicCourseAccuracy);
	If Items.NumeratorOfSettlementCurrency.ChoiceList.FindByValue(NumeratorOfSettlementCurrency) = Undefined Then
		Structure = New Structure("CourseNumerator, CourseDenominator", NumeratorOfSettlementCurrency, DenominatorOfSettlementCurrency); 
		Items.NumeratorOfSettlementCurrency.ChoiceList.Add(Structure, Format(CourseAsOfDate.CourseNumerator, BasicFormatString) + DateText_1);
	EndIf;
	
	If DocumentAmountViewOnly Then
		RecalculateAmountOfSettlementsAtServer();
	Else
		SetTextColorOfFieldsAtServer(Items.NumeratorOfSettlementCurrency.Name, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure CourseOfDocumentProcessingSelectionOnServer(DateOfCourse)
	
	If Not DateOfCourse > CurrentSessionDate() Then
		DateText_1 = " " + StrTemplate(NStr("vi = '(cho %1)';
											|ru = '(на %1)';
											|en = '(by %1)'; fa = '(by %1)';
											|it = '(in %1)';
											|pl = '(na %1)';
											|tr = '(%1 tarihinde)'"), Format(DateOfCourse, "DLF = D"));
	Else
		DateText_1 = "";
	EndIf;
	
	BasicFormatString = StrTemplate("NFD=%1", BasicCourseAccuracy);
	If ARAPCurrency = ComplAccountingCurrency Then
	
		CourseAsOfDate = GetCurrencyRate(DocumentCurrency, DateOfCourse, ComplAccountingCurrency);
		NumeratorOfDocumentCurrency = CourseAsOfDate.CourseNumerator;
		DenominatorOfDocumentCurrency = CourseAsOfDate.CourseDenominator;
		
		If Items.NumeratorOfDocumentCurrency.ChoiceList.FindByValue(NumeratorOfDocumentCurrency) = Undefined Then
			Structure = New Structure("CourseNumerator, CourseDenominator", NumeratorOfDocumentCurrency, DenominatorOfDocumentCurrency); 
			Items.NumeratorOfDocumentCurrency.ChoiceList.Add(Structure,
																Format(CourseAsOfDate.CourseNumerator, BasicFormatString) + DateText_1);
		EndIf;
		
	Else
		
		DocumentCurrencyRateAsOfDate = GetCurrencyRate(DocumentCurrency, DateOfCourse, ComplAccountingCurrency);
		ExchangeRateOfSettlementsAsOfDate = GetCurrencyRate(ARAPCurrency, DateOfCourse, ComplAccountingCurrency);
		
		ConversionRate_1 = ProcessingOfExchangeRatesTM.GetCrossCurrencyExchangeRate(DocumentCurrencyRateAsOfDate,ExchangeRateOfSettlementsAsOfDate);
		
		DenominatorOfDocumentCurrency = ConversionRate_1.CourseDenominator;
		NumeratorOfDocumentCurrency = ConversionRate_1.CourseNumerator;
		
		If Items.NumeratorOfDocumentCurrency.ChoiceList.FindByValue(DenominatorOfDocumentCurrency) = Undefined Then
			Structure = New Structure("CourseNumerator, CourseDenominator", NumeratorOfDocumentCurrency, DenominatorOfDocumentCurrency); 
			Items.NumeratorOfDocumentCurrency.ChoiceList.Add(Structure,
																Format(ConversionRate_1.CourseNumerator, BasicFormatString) + DateText_1);
		EndIf;
		
	EndIf;
	
	If DocumentAmountViewOnly Then
		RecalculateAmountOfSettlementsAtServer();
	Else
		SetTextColorOfFieldsAtServer(Items.NumeratorOfDocumentCurrency.Name, True);
	EndIf;
	
	FillInNumeratorDenominatorLabels();
	SetItemsVisibility();
	
EndProcedure

&AtServer
Procedure DateOfDocumentCurrencyExchangeRateWhenChangedOnServer()
	If DocumentCurrency = ComplAccountingCurrency And Not ARAPCurrency = ComplAccountingCurrency Then 
		CourseAsOfDate = GetCurrencyRate(ARAPCurrency, DocumentExchangeRateDate, ComplAccountingCurrency);
		NumeratorOfSettlementCurrency = CourseAsOfDate.CourseNumerator;
		DenominatorOfSettlementCurrency = CourseAsOfDate.CourseDenominator;
	ElsIf Not DocumentCurrency = ComplAccountingCurrency And ARAPCurrency = ComplAccountingCurrency Then
		CourseAsOfDate = GetCurrencyRate(ARAPCurrency, DocumentExchangeRateDate, ComplAccountingCurrency);
		NumeratorOfSettlementCurrency = CourseAsOfDate.CourseNumerator;
		DenominatorOfSettlementCurrency = CourseAsOfDate.CourseDenominator;
	Else
		DocumentCurrencyRateAsOfDate = GetCurrencyRate(DocumentCurrency, DocumentExchangeRateDate, ComplAccountingCurrency);
		ExchangeRateOfSettlementsAsOfDate = GetCurrencyRate(ARAPCurrency, DocumentExchangeRateDate, ComplAccountingCurrency);
		ConversionRate_1 = ProcessingOfExchangeRatesTM.GetCrossCurrencyExchangeRate(DocumentCurrencyRateAsOfDate,ExchangeRateOfSettlementsAsOfDate);
		DenominatorOfDocumentCurrency = ConversionRate_1.CourseDenominator;
		NumeratorOfDocumentCurrency = ConversionRate_1.CourseNumerator;
	EndIf;
	FillInNumeratorDenominatorLabels();
	SetItemsVisibility();
EndProcedure

&AtClient
Procedure RecalculateTheDocumentAmount(Command)
	
	If DocumentCurrency = ComplAccountingCurrency
		And ARAPCurrency <> ComplAccountingCurrency Then
		
		If DenominatorOfDocumentCurrency = 0 Then
			DocumentAmount = 0;
		Else
			DocumentAmount = Round(AmountARAP * NumeratorOfSettlementCurrency / DenominatorOfSettlementCurrency, 2);
		EndIf;
		
	ElsIf DocumentCurrency = ARAPCurrency Then
		
		DocumentAmount = AmountARAP;
		
	Else
		
		If NumeratorOfDocumentCurrency = 0 Then
			DocumentAmount = 0;
		Else
			DocumentAmount = Round(AmountARAP * DenominatorOfDocumentCurrency / NumeratorOfDocumentCurrency, 2);
		EndIf;
		
	EndIf;
	
	RecalculateDocumentAmounts = DocumentAmount <> TheAmountOfTheDocumentWhenOpened;
	
	SetTextColorOfFields();
	
EndProcedure

&AtClient
Procedure RecalculateMutualSettlementsAmount(Command)
	
	RecalculateAmountOfSettlementsAtServer();
	
	SetTextColorOfFields();
	
EndProcedure

&AtServer
Procedure RecalculateAmountOfSettlementsAtServer()
	
	If ARAPCurrency = ComplAccountingCurrency Or DocumentCurrency = ComplAccountingCurrency Then
		
		If NumeratorOfSettlementCurrency = 0
			Or DenominatorOfSettlementCurrency = 0
			Or NumeratorOfDocumentCurrency = 0
			Or DenominatorOfDocumentCurrency = 0 Then
			AmountARAP = 0;
		Else
			AmountARAP = Round(DocumentAmount * NumeratorOfDocumentCurrency * DenominatorOfSettlementCurrency
				/ (NumeratorOfSettlementCurrency * DenominatorOfDocumentCurrency), 2);
		EndIf;
		
	Else
		
		If DenominatorOfDocumentCurrency = 0 Then
			AmountARAP = 0;
		Else
			AmountARAP = DocumentAmount * NumeratorOfDocumentCurrency / DenominatorOfDocumentCurrency;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecalculateCourseNumeratorOfDocument(Command)
	
	If DocumentCurrency <> ComplAccountingCurrency
		And ARAPCurrency <> ComplAccountingCurrency Then
		Accuracy = 8;
	Else
		Accuracy = BasicCourseAccuracy;
	EndIf;
	If AmountARAP = 0
		Or DenominatorOfSettlementCurrency = 0 Then
		NumeratorOfDocumentCurrency = 0;
	Else
		NumeratorOfDocumentCurrency = Round(AmountARAP / DocumentAmount * DenominatorOfDocumentCurrency, Accuracy);
	EndIf;
	
	SetTextColorOfFields();
	
EndProcedure

&AtClient
Procedure RecalculateExchangeRateNumeratorOfMutualSettlements(Command)
	
	If AmountARAP = 0 Then
		NumeratorOfSettlementCurrency = 0
	Else
		NumeratorOfSettlementCurrency = Round(DocumentAmount * DenominatorOfSettlementCurrency / AmountARAP, BasicCourseAccuracy);
	EndIf;
	
	SetTextColorOfFields();
	
EndProcedure

&AtServer
Procedure UpdateDisplay(CurrencyChanged_)
	
	FillInListOfExchangeRates(CurrencyChanged_);
	If DocumentAmountViewOnly Then
		RecalculateAmountOfSettlementsAtServer();
	EndIf;
	FillInNumeratorDenominatorLabels();
	SetItemsVisibility();
	SetCourseAccuracy();
	
EndProcedure

&AtServer
Procedure SetItemsVisibility()
	
	BothCurrenciesAreFilled = ValueIsFilled(ARAPCurrency) And ValueIsFilled(DocumentCurrency);
	
	VisibilityOfSettlementRate = (ARAPCurrency <> ComplAccountingCurrency 
									And DocumentCurrency = ComplAccountingCurrency 
									And BothCurrenciesAreFilled And Not DonTShowCalculations);
	
	Items.NumeratorOfSettlementCurrency.Visible = VisibilityOfSettlementRate;
	Items.NumeratorOfCurrencyOfMutualSettlementsInscription.Visible = VisibilityOfSettlementRate;
	Items.DenominatorOfSettlementCurrency.Visible = VisibilityOfSettlementRate;
	Items.DenominatorOfCurrencyOfMutualSettlementsInscription.Visible = VisibilityOfSettlementRate;
	Items.TitleNumeratorOfTheSettlementCurrency.Visible = VisibilityOfSettlementRate;
	Items.RecalculateExchangeRateNumeratorOfMutualSettlements.Visible = VisibilityOfSettlementRate;
	
	DocumentCourseVisibility = (DocumentCurrency <> ComplAccountingCurrency 
								And ARAPCurrency <> DocumentCurrency 
								And BothCurrenciesAreFilled And Not DonTShowCalculations);
	
	Items.NumeratorOfDocumentCurrency.Visible = DocumentCourseVisibility;
	Items.NumeratorOfDocumentCurrencyCaption.Visible = DocumentCourseVisibility;
	Items.DenominatorOfDocumentCurrency.Visible = DocumentCourseVisibility;
	Items.DenominatorOfDocumentCurrencyInscription.Visible = DocumentCourseVisibility;
	Items.TitleCourseOfTheDocument.Visible = DocumentCourseVisibility;
	Items.RecalculateCourseNumeratorOfDocument.Visible = DocumentCourseVisibility;
	
	VisibilityOfDateOfDocumentSCurrencyExchangeRate = VisibilityOfDateOfDocumentSCurrencyExchangeRate(
		ThereIsDateOfDocumentSCurrencyExchangeRate, ContractRateOption, 
		DocumentCurrency, ARAPCurrency, 
		ComplAccountingCurrency, CurrencyOfManAccounting);
	Items.GroupDateOfDocumentCurrencyExchangeRate.Visible = VisibilityOfDateOfDocumentSCurrencyExchangeRate;
	If VisibilityOfDateOfDocumentSCurrencyExchangeRate Then
		HeadingOfCourseDate = NStr("vi = 'Phản ánh theo tỷ giá tại ngày:';
									|ru = 'Отразить по курсу на дату:';
									|en = 'Record by rate as of the date:'; fa = 'Record by rate as of the date:';
									|it = 'Visualizzare in base al tasso di cambio alla data:';
									|pl = 'Wyświetl według kursu na datę:';
									|tr = 'Tarihe döviz kurunu yansıt:'");
		If ComplAccountingCurrency = DocumentCurrency 
			Or ComplAccountingCurrency = ARAPCurrency Then
			HeadingOfCourseDate = NStr("vi = 'Phản ánh vào kế toán quản trị theo tỷ giá tại ngày:';
										|ru = 'Отразить в упр. учете по курсу на дату:';
										|en = 'Record in management accounting by rate as of the date:'; fa = 'Record in management accounting by rate as of the date:';
										|it = 'Visualizzare in contabilità gest. in base al tasso di cambio alla data:';
										|pl = 'Wyświetl w ewidencji zarz. według kursu na datę:';
										|tr = 'Yönetim muhasebesine tarihe döviz kuru ile yansıt:'");
		ElsIf CurrencyOfManAccounting = DocumentCurrency 
			Or CurrencyOfManAccounting = ARAPCurrency Then
			HeadingOfCourseDate = NStr("vi = 'Phản ánh vào kế toán tài chính theo tỷ giá tại ngày:';
										|ru = 'Отразить в регл. учете по курсу на дату:';
										|en = 'Record in local accounting by rate as of the date:'; fa = 'Record in local accounting by rate as of the date:';
										|it = 'Visualizzare in contabilità regol. in base al tasso di cambio alla data:';
										|pl = 'Wyświetl w ewidencji regl według kursu na dzień:';
										|tr = 'Yerel muhasebeye tarihe döviz kuru ile yansıt:'");
		EndIf;
		If Not Items.ReflectExchangeRateOnDate.Title = HeadingOfCourseDate Then
			Items.ReflectExchangeRateOnDate.Title = HeadingOfCourseDate
		EndIf;
	EndIf;
	Items.ContractRateOption.Visible = ARAPCurrency <> ComplAccountingCurrency;
	Items.ContractRateOption.Hyperlink = 
		ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract;
	
	Items.DocumentAmountField.Visible = DocumentAmount <> 0;
	Items.AmountARAP.Visible = Not DonTShowCalculations And DocumentAmount <> 0;
	Items.TitleSettlementAmount.Visible = Not DonTShowCalculations;
	Items.ARAPCurrency.Visible = Not DonTShowCalculations;
	
	If ThisIsASalesDocument And Not Users.RolesAvailable("ChangeSaleDocumentRate") 
		Or ThisIsAPurchaseDocument And Not Users.RolesAvailable("ChangePurchaseDocumentRate") Then
		
		ReadOnly = True;
		
	Else
		
		Items.AmountARAP.ReadOnly = DocumentCurrency = ARAPCurrency
														Or DocumentAmount = 0
														Or ReadOnly;
		Items.DocumentAmountField.ReadOnly  = DocumentCurrency = ARAPCurrency
														Or DocumentAmount = 0
														Or DocumentAmountViewOnly
														Or ReadOnly;
		
		Items.DocumentCurrency.ReadOnly = DocumentCurrencyViewOnly Or ReadOnly;
		Items.ARAPCurrency.ReadOnly = MutualSettlementsCurrencyViewOnly Or ReadOnly;
		Items.NumeratorOfSettlementCurrency.ReadOnly = ReadOnly;
		Items.NumeratorOfDocumentCurrency.ReadOnly = ReadOnly;
		
	EndIf;
	
	Items.RecalculateTheDocumentAmount.Enabled              = Not (DocumentAmountViewOnly 
																		Or DocumentCurrency = ARAPCurrency
																		Or DocumentAmount = 0
																		Or ReadOnly);
	Items.RecalculateCourseNumeratorOfDocument.Enabled      = Not ReadOnly;
	Items.RecalculateMutualSettlementsAmount.Enabled         = Not (ReadOnly
																		Or DocumentCurrency = ARAPCurrency
																		Or DocumentAmount = 0);
	Items.RecalculateExchangeRateNumeratorOfMutualSettlements.Enabled = Not ReadOnly;
	
	Items.FormMoveToDocument.Enabled = Not ReadOnly;
	
EndProcedure

&AtServer
Procedure SetCourseAccuracy()
	
	BasicFormatString = StrTemplate("NFD=%1", BasicCourseAccuracy);
	If DocumentCurrency <> ComplAccountingCurrency
		And ARAPCurrency <> ComplAccountingCurrency Then
		Items.NumeratorOfDocumentCurrency.Width = 11;
		Items.DenominatorOfDocumentCurrency.Width = 11;
		Items.NumeratorOfDocumentCurrency.EditFormat = "NFD=8";
		Items.DenominatorOfDocumentCurrency.EditFormat = "NFD=8";
	Else
		Items.NumeratorOfDocumentCurrency.Width = 7;
		Items.DenominatorOfDocumentCurrency.Width = 7;
		Items.NumeratorOfDocumentCurrency.EditFormat = BasicFormatString;
		Items.DenominatorOfDocumentCurrency.EditFormat = BasicFormatString;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInNumeratorDenominatorLabels()
	
	NumeratorOfCurrencyOfMutualSettlementsInscription = "" + DocumentCurrency + " =";
	DenominatorOfCurrencyOfMutualSettlementsInscription = "" + ARAPCurrency;
	
	NumeratorOfDocumentCurrencyCaption = "" + ARAPCurrency + " =";
	DenominatorOfDocumentCurrencyInscription = "" + DocumentCurrency;
	
EndProcedure

&AtServer
Function CourseIsOnList(List, CourseNumerator, CourseDenominator)
	
	CourseFound = False;
	For Each ChoiceItem In List Do
		ElementValue = ChoiceItem.Value;
		If TypeOf(ElementValue) = Type("Structure") Then 
			If CourseNumerator = ElementValue.CourseNumerator
				And CourseDenominator = ElementValue.CourseDenominator Then
				CourseFound = True;
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	Return CourseFound;
	
EndFunction

&AtClientAtServerNoContext
Function VisibilityOfDateOfDocumentSCurrencyExchangeRate(ThereIsDateOfDocumentSCurrencyExchangeRate, ContractRateOption, DocumentCurrency, ARAPCurrency, ComplAccountingCurrency, CurrencyOfManAccounting)
	Return 
		ThereIsDateOfDocumentSCurrencyExchangeRate
		And ContractRateOption = PredefinedValue("Enum.ContractRateOptions.Mutable")
		And Not ((ComplAccountingCurrency = DocumentCurrency 
				Or ComplAccountingCurrency = ARAPCurrency)
			And (CurrencyOfManAccounting = DocumentCurrency 
				Or CurrencyOfManAccounting = ARAPCurrency));
EndFunction

&AtClient
Procedure SetTextColorOfFields(NameOfModifiedField = "", HighlightInRed_ = False)
	
	SetTextColorOfFieldsAtServer(NameOfModifiedField, HighlightInRed_);
	
EndProcedure

&AtServer
Procedure SetTextColorOfFieldsAtServer(NameOfModifiedField = "", HighlightInRed_ = False)
	
	ThereAreMismatches = ThereAreFieldInconsistencies();
	If HighlightInRed_ 
		And ThereAreMismatches
		Or Not HighlightInRed_ Then
		FieldsNames = New Array;
		FieldsNames.Add(Items.AmountARAP.Name);
		FieldsNames.Add(Items.DocumentAmountField.Name);
		FieldsNames.Add(Items.NumeratorOfSettlementCurrency.Name);
		FieldsNames.Add(Items.NumeratorOfDocumentCurrency.Name);
		
		For Each FieldName In FieldsNames Do
			If FieldName = NameOfModifiedField Then
				Continue;
			EndIf;
			Items[FieldName].TextColor = ?(HighlightInRed_, StyleColors.InvalidData, New Color);
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Function ThereAreFieldInconsistencies()
	
	If ValueIsFilled(ARAPCurrency)
		And ValueIsFilled(DocumentCurrency)
		And DocumentCurrency <> ARAPCurrency Then
		If DocumentCurrency = ComplAccountingCurrency Then
			If NumeratorOfSettlementCurrency = 0
				Or DenominatorOfSettlementCurrency = 0
				Or AmountARAP = 0 Then 
				Return False;
			Else
				Return DocumentAmount <> Round(AmountARAP * NumeratorOfSettlementCurrency / DenominatorOfSettlementCurrency, 2)
							And AmountARAP <> Round(DocumentAmount * DenominatorOfSettlementCurrency / NumeratorOfSettlementCurrency, 2)
							And NumeratorOfSettlementCurrency <> Round(DocumentAmount * DenominatorOfSettlementCurrency / AmountARAP, BasicCourseAccuracy);
			EndIf;
		Else
			If NumeratorOfDocumentCurrency = 0
				Or DenominatorOfDocumentCurrency = 0
				Or DocumentAmount = 0 Then 
				Return False;
			Else
				If DocumentCurrency <> ComplAccountingCurrency
					And ARAPCurrency <> ComplAccountingCurrency Then
					Accuracy = 8;
				Else
					Accuracy = BasicCourseAccuracy;
				EndIf;
				Return DocumentAmount <> Round(AmountARAP * DenominatorOfDocumentCurrency / NumeratorOfDocumentCurrency, 2)
							And AmountARAP <> Round(DocumentAmount * NumeratorOfDocumentCurrency / DenominatorOfDocumentCurrency, 2)
							And NumeratorOfDocumentCurrency <> Round(AmountARAP / DocumentAmount * DenominatorOfDocumentCurrency, Accuracy);
			EndIf;
		EndIf;
	Else
		Return AmountARAP <> DocumentAmount;
	EndIf;
	
EndFunction;


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
	If Item.Name = "sh_ShamsiInput_F_DocumentExchangeRateDate" Then
		DocumentExchangeRateDateOnChange(Items.DocumentExchangeRateDate);
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
