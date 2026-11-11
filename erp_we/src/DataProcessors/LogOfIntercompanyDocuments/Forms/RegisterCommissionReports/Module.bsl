
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("FormAssignmentKey")
		And ValueIsFilled(Parameters.FormAssignmentKey) Then
		
		PurposeUseKey = Parameters.FormAssignmentKey;
		
	Else
		PurposeUseKey = DefaultFormAssignmentKey();
	EndIf;
	
	RestoreSettings(Parameters);
	CustomizeWithLinkSeeAlso();	
	// When opening from the processing of the "Closing operation of the month", it is necessary to hide the selections.
	Items.Consignor.Visible    = Not Parameters.Property("RegistrationPeriod");
	Items.Consignee.Visible = Not Parameters.Property("RegistrationPeriod");
	
	FillInGoodsForRegistration();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PeriodPresentation = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period.StartDate);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		ShouldSaveSettings();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_CommissionReportIntercompany"
		Or EventName = "Write_CommissionWriteOffReportIntercompany" Then
		
		FillInGoodsForRegistration();
		
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PeriodPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification     = New CallbackDescription("PeriodPresentationStartChoiceCompletion", ThisObject);
	FormParameters = New Structure("Value, PeriodSelectionMode", Period.StartDate, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection", FormParameters, ThisObject, ThisObject.UUID, , ,
		Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PeriodPresentationStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export
	
	If SelectedPeriod <> Undefined Then
		StartDate    = BegOfMonth(SelectedPeriod);
		EndDate = EndOfMonth(SelectedPeriod);
		
		Period.StartDate    = StartDate;
		Period.EndDate = EndDate;
		
		PeriodPresentation = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period.StartDate);
		
		FillInGoodsForRegistration();
	EndIf;
	
EndProcedure

&AtClient
Procedure PeriodPresentationTuning(Item, Direction, StandardProcessing)
	
	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(Direction, StandardProcessing,
		Period.StartDate, PeriodPresentation);
	
	Period.EndDate = EndOfMonth(Period.StartDate);
	
	StartDate    = Period.StartDate;
	EndDate = Period.EndDate;
	
	FillInGoodsForRegistration();
	
EndProcedure

&AtClient
Procedure PeriodStartDate_OnChange(Item)
	
	ClearMessages();
	SetSelectionByPeriod();
	
EndProcedure

&AtClient
Procedure PeriodEndDate_2OnChange(Item)
	
	ClearMessages();
	SetSelectionByPeriod();
	
EndProcedure

&AtClient
Procedure ConsignorOnChange(Item)
	
	FillInGoodsForRegistration();
	
EndProcedure

&AtClient
Procedure ConsigneeOnChange(Item)
	
	FillInGoodsForRegistration();
	
EndProcedure

#EndRegion

#Region EventHandlersForListElements

&AtClient
Procedure GoodsToBeRegisteredInReportsToConsignorBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateACommissionReport(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.LogOfIntercompanyDocuments.RegisterCommissionReports.Command.CreateACommissionReport");
	
	String = Items.GoodsToBeRegisteredInReportsToConsignor.CurrentData;
	
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(
		String, LogParameters()) Then
		Return;
	EndIf;
	
	If String <> Undefined Then
		
		StructureBase = New Structure();
		StructureBase.Insert("BeginOfPeriod",                 Period.StartDate);
		StructureBase.Insert("EndOfPeriod",                  Period.EndDate);
		StructureBase.Insert("Organization",                   String.Consignor);
		StructureBase.Insert("Consignee",                   String.Consignee);
		StructureBase.Insert("Currency",                        String.Currency);
		StructureBase.Insert("Contract",                       String.Contract);
		StructureBase.Insert("PriceKind",                       String.PriceKind);
		StructureBase.Insert("VATTaxation",			 String.VATTaxation);
		StructureBase.Insert("FillInByTheGoodsForRegistration", True);
		
		ParametersStructure1 = New Structure("Basis", StructureBase);
		
		If String.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CommissionReportIntercompany") Then
			OpenForm("Document.CommissionReportIntercompany.ObjectForm", ParametersStructure1, ThisObject);
		Else
			OpenForm("Document.CommissionWriteOffReportIntercompany.ObjectForm", ParametersStructure1, ThisObject);
		EndIf;
	Else
		ShowMessageBox(,NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chỉ ra!';
							|ru = 'Команда не может быть выполнена для указанного объекта!';
							|en = 'Cannot execute this command for the specified object.'; fa = 'Cannot execute this command for the specified object.';
							|it = 'Il comando non può essere eseguito per oggetto indicato!';
							|pl = 'Nie można wykonać polecenia dla wskazanego obiektu!';
							|tr = 'Komut belirtilen nesne için gerçekleştirilemez!'"));
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	FillInGoodsForRegistration();
	
EndProcedure

&AtClient
Procedure SeeAlsoInProgressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization", Consignor);
	QuickFilterStructure.Insert("StorageLocation", Undefined);
	
	LogParameters = New Structure;
	LogParameters.Insert("QuickFilterStructure",QuickFilterStructure);
	LogParameters.Insert("PurposeUseKey","CommissionReportIntercompany");
		
	LogParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	
	OpenForm(FormattedStringURL, LogParameters); 
EndProcedure


#EndRegion

#Region Private

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "DocumentsBetweenCompaniesAll";
	
EndFunction

&AtServer
Procedure RestoreSettings(Var_Parameters)
	
	If Var_Parameters.Property("RegistrationPeriod") Then
		FormIsOpenedByHyperlink = True;
		
		Consignor    = Var_Parameters.Organization;
		Consignee = Var_Parameters.Organization;
		
		StartDate     = BegOfMonth(Var_Parameters.RegistrationPeriod);
		EndDate = EndOfMonth(Var_Parameters.RegistrationPeriod);
		
		Period.StartDate    = StartDate;
		Period.EndDate = EndDate;
	ElsIf Var_Parameters.Property("ListFormSelections") Then
		FormIsOpenedByHyperlink = True;
		
		Consignor = Var_Parameters.ListFormSelections.Organization;
		
		StartDate     = BegOfMonth(CurrentSessionDate());;
		EndDate = EndOfMonth(StartDate);
		
		Period.StartDate    = StartDate;
		Period.EndDate = EndDate;
	Else
		FormIsOpenedByHyperlink = False;
		
		ObjectKey = "DataProcessor.LogOfIntercompanyDocuments.Form.RegisterCommissionReports_1";
		Settings   = Common.CommonSettingsStorageLoad(ObjectKey, PurposeUseKey);
		
		If Settings <> Undefined Then
			Period         = Settings.Period;
			StartDate     = Period.StartDate;
			EndDate = Period.EndDate;
			
			Consignor    = Settings.Consignor;
			Consignee = Settings.Consignee;
		Else
			StartDate     = BegOfMonth(CurrentSessionDate());
			EndDate = EndOfMonth(StartDate);
			
			Period.StartDate    = StartDate;
			Period.EndDate = EndDate;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInGoodsForRegistration()
	
	QueryText = DataProcessors.LogOfIntercompanyDocuments.RequestTextCommissionReportsIssued();
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = QueryText;
	
	TextSalesReport = NStr("vi = 'Báo cáo bán hàng';
							|ru = 'Отчет о продажах';
							|en = 'Consignment sale'; fa = 'فروش امانی';
							|it = 'Report sulle vendite';
							|pl = 'Raport o sprzedaży';
							|tr = 'Satış raporu'");
	TextReportOnDebiting = NStr("vi = 'Báo cáo ghi giảm';
								|ru = 'Отчет о списании';
								|en = 'Stock adjustment'; fa = 'Stock adjustment';
								|it = 'Report sullo storno';
								|pl = 'Raport o rozchodzie';
								|tr = 'Gider yazma raporu'");
	
	EndOfPeriod  = New Boundary(EndOfDay(Period.EndDate), BoundaryType.Including);
	
	Query.SetParameter("Consignor", Consignor);
	Query.SetParameter("SelectionByCommitteeIsEstablished", ValueIsFilled(Consignor));
	Query.SetParameter("Consignee", Consignee);
	Query.SetParameter("SelectionByCommissionAgentIsEstablished", ValueIsFilled(Consignee));
	Query.SetParameter("InitialBorder", Period.StartDate);
	Query.SetParameter("ConBorder", EndOfPeriod);
	Query.SetParameter("TextSalesReport", TextSalesReport);
	Query.SetParameter("TextReportOnDebiting", TextReportOnDebiting);
	Query.SetParameter("SelectBySale", True);
	Query.SetParameter("SelectByDebit", True);
	
	AccountingPoliciesTaxSettings.SupplementTemporaryTableManagerWithCurrentParametersForAccountingPolicies(
		Metadata.InformationRegisters.TaxationSystemSettings.Name,
		Query.TempTablesManager,
		EndOfDay(Period.EndDate),
		"TTAccountingPoliciesOfOrganizations",
		?(ValueIsFilled(Consignor), Consignor, Undefined));
	
	QueryResult = Query.Execute().Unload();
	
	GoodsToBeRegisteredInReportsToConsignor.Load(QueryResult);
	
	Items.GoodsToBeRegisteredInReportsToConsignor.Refresh();
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	If FormIsOpenedByHyperlink Then
		Return;
	EndIf;
	
	ObjectKey = "DataProcessor.LogOfIntercompanyDocuments.Form.RegisterCommissionReports_1";
	AttributesToSaveNames = "Period,Consignor,Consignee";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, ThisForm);
	
	Common.CommonSettingsStorageSave(ObjectKey, PurposeUseKey, Settings);
	
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	Cancel = False;
	
	If Period.StartDate > Period.EndDate Then
		Period.StartDate		= StartDate;
		Period.EndDate	= EndDate;
		
		MessageText = NStr("vi = 'Ngày bắt đầu kỳ không thể lớn hơn ngày kết thúc';
							|ru = 'Дата начала периода не может быть больше даты окончания периода';
							|en = 'The period start date cannot be greater than the period end date'; fa = 'The period start date cannot be greater than the period end date';
							|it = 'La data di inizio periodo non può essere superiore alla data del termine periodo';
							|pl = 'Data rozpoczęcia okresu nie może być dłuższa niż data zakończenia okresu';
							|tr = 'Dönemin başlangıç tarihi, dönemin bitiş tarihinden büyük olamaz'");
		
		Common.MessageToUser(MessageText, , "PeriodStartDate_", "Period.StartDate", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Period.StartDate)
		Or Not ValueIsFilled(Period.EndDate)
		Or Month(Period.StartDate) <> Month(Period.EndDate)
		Or Year(Period.StartDate) <> Year(Period.EndDate) Then
		
		Period.StartDate		= StartDate;
		Period.EndDate	= EndDate;
		
		MessageText = NStr("vi = 'Ngày đầu kỳ và ngày cuối kỳ phải nằm trong một tháng';
							|ru = 'Дата начала периода и дата окончания периода должны находиться в пределах одного месяца';
							|en = 'Period start date and period end date should be within one month'; fa = 'Period start date and period end date should be within one month';
							|it = 'La data di inizio periodo e la data del termine periodo devono stare nello stesso mese';
							|pl = 'Data początku i data zakończenia okresu muszą znajdować się w obrębie jednego miesiąca';
							|tr = 'Dönemin başlangıç tarihi ve bitiş tarihi bir ay içinde olmalıdır'");
		
		Common.MessageToUser(MessageText, , , , Cancel);
		
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	StartDate		= Period.StartDate;
	EndDate	= Period.EndDate;
	
	FillInGoodsForRegistration();
	
EndProcedure

&AtServer
Procedure CustomizeWithLinkSeeAlso()
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("PurposeUseKey", "CommissionReportIntercompany");
	
	ArrayCalculationManagersSeeAlsoInWork = New Array();
	ArrayCalculationManagersSeeAlsoInWork.Add("DataProcessor.LogOfIntercompanyDocuments");
		
	SeeAlsoInProgress = TMCommonUse.CreateHyperlinkSeeAlsoIn(ArrayCalculationManagersSeeAlsoInWork, GenerationParameters);
	Items.SeeAlsoInProgress.Visible = ValueIsFilled(SeeAlsoInProgress);
	
EndProcedure

&AtClient
Function LogParameters()
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",   Consignee);
	QuickFilterStructure.Insert("StorageLocation", Undefined);
	
	LogParameters = New Structure;
	LogParameters.Insert("QuickFilterStructure",	QuickFilterStructure);
	LogParameters.Insert("WorkplaceName",			"LogOfIntercompanyDocuments");
	LogParameters.Insert("FormAssignmentKey",		PurposeUseKey);
	LogParameters.Insert("JournalSynonym", NStr("vi = 'Chứng từ giữa các doanh nghiệp';
												|ru = 'Документы между организациями';
												|en = 'Documents between companies'; fa = 'Documents between companies';
												|it = 'Documenti tra organizzazioni';
												|pl = 'Dokumenty międzyfirmowe';
												|tr = 'İş yerleri arasındaki belgeler'"));
	
	Return LogParameters;
	
EndFunction

#EndRegion
