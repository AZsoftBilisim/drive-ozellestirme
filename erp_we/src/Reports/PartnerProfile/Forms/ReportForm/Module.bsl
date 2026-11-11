
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("CommandParameter") Then
		Partner = Parameters.CommandParameter;
	ElsIf Parameters.Property("Partner") Then
		Partner = Parameters.Partner;
	Else
		Cancel = True;
	EndIf;
	
	Items.UpdateCalculations.Visible = Not GetFunctionalOption("NewOnlineARAPAccounting");
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		Title = NStr("vi = 'Hồ sơ đối tác';
					|ru = 'Досье контрагента';
					|en = 'Counterparty profile'; fa = 'Counterparty profile';
					|it = 'Profilo del contraente';
					|pl = 'Akta kontrahenta';
					|tr = 'Cari hesap dosyası'");
	Else
		Title = NStr("vi = 'Hồ sơ bạn hàng';
					|ru = 'Досье партнера';
					|en = 'Partner profile'; fa = 'نمایه شریک';
					|it = 'Profilo del partner';
					|pl = 'Akta partnera';
					|tr = 'İş ortağı dosyası'");
	EndIf;
	
	If ValueIsFilled(Partner) Then 
		
		If TypeOf(Partner) = Type("CatalogRef.Partners") Then
			Partners.Add(Partner);
		ElsIf TypeOf(Partner) = Type("Array") Then
			Partners.LoadValues(Partner);
		EndIf;
	EndIf;
	
	If Not Cancel Then
		Report.DebtClassificationOption = GeneralPurposeTMServerCall.DefaultDebtClassificationOption(True);
		
		LoadSettings();
		VisibilityManagement();
		GenerateReport();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		ShouldSaveSettings();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Report.PartnerProfile.ReportForm.Command.Generate");
	
	ClearMessages();
	
	GenerateReport();
	
EndProcedure 

&AtClient
Procedure UpdateCalculations(Command)
	
	ResponseCode = Undefined;

	
	ShowQueryBox(New CallbackDescription("UpdateCalculationsCompletion", ThisObject), NStr("vi = 'Cập nhật công nợ với khách hàng?';
																							|ru = 'Актуализировать расчеты с клиентами?';
																							|en = 'Update customer AR/AP?'; fa = 'Update customer AR/AP?';
																							|it = 'Aggiornare i regolamenti con clienti?';
																							|pl = 'Chcesz zaktualizować rozliczenia z klientami?';
																							|tr = 'İstemcilerle mutabakatları güncelle?'"), QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure UpdateCalculationsCompletion(QuestionResult, AdditionalParameters) Export
    
    ResponseCode = QuestionResult;
    If ResponseCode = DialogReturnCode.Yes Then
        
        UpdateCalculationsUpdateReport();
        ShowUserNotification(
        NStr("vi = 'Thiết thực hóa công nợ';
			|ru = 'Расчеты актуализированы';
			|en = 'Settlements are updated'; fa = 'Settlements are updated';
			|it = 'Pagamenti aggiornati';
			|pl = 'Rozliczenia są zaktualizowane';
			|tr = 'Mutabakatlar güncellendi'"),
        , // URL
        NStr("vi = 'Thiết thực hóa công nợ với khách hàng';
			|ru = 'Расчеты с клиентами актуализированы';
			|en = 'Customer AR/AP are updated'; fa = 'Customer AR/AP are updated';
			|it = 'Regolamenti con clienti aggiornati';
			|pl = 'Rozliczenia z klientami zaktualizowane';
			|tr = 'İstemcilerle mutabakatlar güncellendi'"));
        
    EndIf;

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateReport()
	
	ReportTable.Clear();
	ObjectReport =  FormAttributeToValue("Report");
	
	For Each Partner In Partners Do
		
		ObjectReport.GenerateReport(ReportTable,Partner.Value)
		
	EndDo;
	
	Report.ThereAreCustomersARAPRequireUpdate 	= ObjectReport.ThereAreCustomersARAPRequireUpdate;
	Report.ThereAreVendorsARAPRequireUpdate 	= ObjectReport.ThereAreVendorsARAPRequireUpdate;
	
	AvailabilityControl();
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()

	Var Settings;
	
	Settings = New Structure;
	Settings.Insert("Contacts",Report.Contacts);
	Settings.Insert("CurrentActivity",Report.CurrentActivity);
	Settings.Insert("ClientData",Report.ClientData);
	Settings.Insert("VendorData",Report.VendorData);
	Settings.Insert("Classification",Report.Classification);
	
	Common.CommonSettingsStorageSave("Report.PartnerInfoProfile", "ReportForm", Settings);
	
EndProcedure

&AtServer
Procedure LoadSettings()

	Var SettingsValue;
	
	SettingsValue = Common.CommonSettingsStorageLoad("Report.PartnerInfoProfile", "ReportForm");
	If SettingsValue = Undefined Then
		
		Report.Contacts			= True;
		Report.ClientData		= True;
		Report.VendorData	= True;
		Report.CurrentActivity	= True;
		Report.Classification		= True;
		
	ElsIf TypeOf(SettingsValue) = Type("Structure") Then
		
		SettingsValue.Property("Contacts",Report.Contacts);
		SettingsValue.Property("CurrentActivity",Report.CurrentActivity);
		SettingsValue.Property("ClientData",Report.ClientData);
		SettingsValue.Property("VendorData",Report.VendorData);
		SettingsValue.Property("Classification",Report.Classification);
		
	EndIf;

EndProcedure

&AtServer
Procedure VisibilityManagement()
	
	If Not AccessRight("Read",Metadata.Catalogs.ContactPersonsForPartners)
	     And Not AccessRight("Read",Metadata.Catalogs.Counterparties) Then
		
		Report.Contacts = False;
		Items.Contacts.Visible = False;
		
	EndIf;
	
	If Not AccessRight("Read",Metadata.Catalogs.SalesOpportunitiesToCustomer)
	     And Not AccessRight("Read",Metadata.Documents.SalesOrder)
	     And Not AccessRight("Read",Metadata.AccumulationRegisters.CustomersARAPAccountingByDocuments)
	     And Not AccessRight("Read",Metadata.Catalogs.TermsOfSale) Then
		
		Report.ClientData = False;
		Items.ClientData.Visible = False;
		
	EndIf;
	
	If Not AccessRight("Read",Metadata.AccumulationRegisters.VendorsARAPAccountingByDocuments)
		And Not AccessRight("Read",Metadata.Catalogs.TermsOfPurchaseFromVendors)
		And Not AccessRight("Read",Metadata.Documents.PurchaseOrder) Then
		
		Report.VendorData = False;
		Items.VendorData.Visible = False;
		
	EndIf;
	
	CurActivityUnavailableByFO = Not GetFunctionalOption("UseEmailClient")
	                                 And Not GetFunctionalOption("UseMarketingActivities")
	                                 And Not GetFunctionalOption("UseProjects");
	
	
	If CurActivityUnavailableByFO 
	     Or (Not AccessRight("Read",Metadata.Documents.PlannedInteraction)
	          And Not AccessRight("Read",Metadata.Documents.Meeting)
	          And Not AccessRight("Read",Metadata.Documents.PhoneCall)
	          And Not AccessRight("Read",Metadata.Documents.IncomingEmail)
	          And Not AccessRight("Read",Metadata.Documents.OutgoingEmail)
	          And Not AccessRight("Read",Metadata.Catalogs.MarketingActivities)
	          And Not AccessRight("Read",Metadata.Catalogs.Projects)) Then
	
		Report.CurrentActivity = False;
		Items.CurrentActivity.Visible = False;
	
	EndIf;
	
	ClassificationIsNotAvailableByFO = (Not GetFunctionalOption("UseABCXYZClassificationOfPartnersByGrossProfit")
	                             And Not GetFunctionalOption("UseABCXYZClassificationOfPartnersByRevenue")
	                             And Not GetFunctionalOption("UseABCXYZClassificationOfPartnersByNumberOfSales") 
	                             And Not GetFunctionalOption("UsePartnersSegments"));
	
	If ClassificationIsNotAvailableByFO 
	    Or (Not AccessRight("Read",Metadata.InformationRegisters.ABCXYZCustomerClassification) 
		And Not AccessRight("Read",Metadata.InformationRegisters.SegmentPartners)) Then
		
		Report.Classification = False;
		Items.Classification.Visible = False;
		
	EndIf;

EndProcedure

&AtServer
Procedure AvailabilityControl()

	Items.UpdateCalculations.Enabled = Report.ThereAreCustomersARAPRequireUpdate Or Report.ThereAreVendorsARAPRequireUpdate;

EndProcedure

&AtServer
Function AnalyticsForUpdatingCalculations()

	Query = New Query;
	Query.Text = "SELECT ALLOWED DISTINCT
	|	AccountingDimensionByPartners.DimensionKey
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|WHERE
	|	AccountingDimensionByPartners.Partner IN(&ArrayOfPartners)";
	
	Query.SetParameter("ArrayOfPartners", Partners.UnloadValues());
	
	Return Query.Execute().Unload().UnloadColumn("DimensionKey");
	
EndFunction

&AtServer
Procedure UpdateCalculationsUpdateReport()
	
	If Report.ThereAreCustomersARAPRequireUpdate Or Report.ThereAreVendorsARAPRequireUpdate Then
		ArrayOfAnalyticsToUpdate = AnalyticsForUpdatingCalculations();
	EndIf;
	
	If Report.ThereAreCustomersARAPRequireUpdate And ArrayOfAnalyticsToUpdate.Count() > 0 Then
		CalculationEnd = EndOfMonth(CurrentSessionDate()) + 1;
		CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
		CalculationAnalysts.AccountingAnalyticsForPartners = ArrayOfAnalyticsToUpdate;
		ARAPAllocationServerCall.DistributeAllSettlementsWithCustomers(CalculationEnd, CalculationAnalysts);
		Report.ThereAreCustomersARAPRequireUpdate = False;
	EndIf;
	
	If Report.ThereAreVendorsARAPRequireUpdate And ArrayOfAnalyticsToUpdate.Count() > 0 Then
		CalculationEnd = EndOfMonth(CurrentSessionDate()) + 1;
		CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
		CalculationAnalysts.AccountingAnalyticsForPartners = ArrayOfAnalyticsToUpdate;
		ARAPAllocationServerCall.DistributeAllSettlementsWithSuppliers(CalculationEnd, CalculationAnalysts);
		Report.ThereAreVendorsARAPRequireUpdate = False;
	EndIf;
	
	GenerateReport();
	
EndProcedure

#EndRegion
