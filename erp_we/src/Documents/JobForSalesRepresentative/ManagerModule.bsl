#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Command = Documents.SalesOrder.AddGenerateCommand(GenerationCommands);
	If Not Command = Undefined Then
		
		Command.WriteMode = "Write";
		
	EndIf;
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds the "Task to sales representative" document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.JobForSalesRepresentative) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.JobForSalesRepresentative.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.JobForSalesRepresentative);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseJobsToManageSalesRepresentatives,UseJobsToSalesRepresentativesForPlanning";

		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	If GetFunctionalOption("ToUseTermsOfSales") Then
		Reports.VariancesFromSalesTermsAndConditions.AddReportCommand(ReportsCommands);
	EndIf;
	
EndProcedure

// Fills in the passed array with the names of banking details for the specified business transaction.
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions - value of the business transaction.
//  ArrayOfAllProps - Array - contains the names of all Bank details.
//  ArrayOfOperationDetails - Array - contains the names of banking details for the specified business transaction.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	
	ArrayOfAllProps.Add("PackageDepositIsRequired");
	ArrayOfAllProps.Add("VATTaxation");
	
	ArrayOfAllProps.Add("Goods.PercentRateOfManualDiscount");
	ArrayOfAllProps.Add("Goods.ManualDiscount");
	
	ArrayOfOperationDetails = New Array;
	If BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
		Or Not ValueIsFilled(BusinessOperation) Then
		
		ArrayOfOperationDetails.Add("PackageDepositIsRequired");
		ArrayOfOperationDetails.Add("VATTaxation");
		
		ArrayOfOperationDetails.Add("Goods.PercentRateOfManualDiscount");
		ArrayOfOperationDetails.Add("Goods.ManualDiscount");
		
	EndIf;
	
EndProcedure

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.JobForSalesRepresentative - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = Object.Date;
	FillParameters.Warehouse = Object.Warehouse;
	FillParameters.Contract = Object.Contract;
	FillParameters.ThisIsOrder = True;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer Then
		
		FillParameters.GoodsSales = True;
		FillParameters.ImplementationOfWorksServices = True;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		
		FillParameters.TransferToCommissionAgent = True;
		
	EndIf;
	
	Return FillParameters;
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters- Array of parameters of the functions of the settlement mechanism
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	ParametersStructure.ThisIsOrder                         = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	#Region OptionalParameters
	
	ParametersStructure.LineOfBusiness          = "";
	ParametersStructure.DocumentAmountForm              = "Form.AmountOrdered";
	ParametersStructure.AmountOfDepositForContainerForm           = "Form.PackageDepositValue"; 
	ParametersStructure.ARAPObjectSettings                  = Enums.ARAPObjectSettings.ByOrders;
	
	//The tabular part, according to which the amount of mutual settlements is distributed, is the "order" field.
	//It is used to display hyperlinks, edit and fill in the schedule of scheduled payments
	//, edit the payment transcript if the Summadocumentform parameter is not filled in.
	//In PM, the objects of calculations for orders are filled in.
	ParametersStructure.PathToTSData                    = "Object.Goods";
	
	//They are used to determine the value of payments in currency and in the form of editing payment rules.
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.CompanyBankAccount        = "";
	ParametersStructure.CashAccount                            = "";
	ParametersStructure.ForeignCurrencyTransaction                    = "";
	//It is used in the form of payment rules and for the selection of settlement objects in the decryption of the payment.
	ParametersStructure.PaymentID             = "";
	
	//The details for the object of calculations are used in conducting.
	ParametersStructure.FinancialAccountingGroup           = "";
	ParametersStructure.Department                    = "";
	
	#EndRegion
	
	#Region ScheduledPaymentScheduleAndPaymentDate
	
	//Function Payment stages and payment date
	ParametersStructure.PathToTSDataPaymentSteps         = "Object.PaymentScheduleSteps";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStepsText";
	ParametersStructure.PaymentSchedule                     = "Object.PaymentSchedule";
	ParametersStructure.DateOfShipment                     = "Object.RequestShipmentOn";
	ParametersStructure.SourceOfAmountsTabularPart       = True;
	ParametersStructure.ShipInOneDay              = "Object.NotShipInInstallments";
	
	//The name of the hyperlink that displays the current payment rules of the document and opens the Payment Rules form.
	ParametersStructure.FormItems.InscriptionStages             = "DecorationPaymentSteps";

	//Hides a bank account, cash register, payment in foreign currency and UIP in the form of payment melting, used in self-service.
	ParametersStructure.DoNotSpecifyPaymentSources = True;
	
	#EndRegion
	
	Return ParametersStructure;
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Partner)
	|	AND( ValueAllowed(Warehouse)
	|	OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|	)AND( ValueAllowed(Organization)
	|	OR Organization = VALUE(Catalog.Companies.EmptyRef)
	|	) ";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Private

  //Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// The form of the task
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "JobTemplate";
	PrintCommand.Presentation = NStr("vi = 'Mẫu nhiệm vụ';
									|ru = 'Бланк задания';
									|en = 'Task template'; fa = 'الگوی وظیفه';
									|it = 'Modulo del task';
									|pl = 'Druk zadania';
									|tr = 'Görev formu'");

	// Summary task
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "SummaryJob";
	PrintCommand.Presentation = NStr("vi = 'Nhiệm vụ tổng hợp';
									|ru = 'Сводное задание';
									|en = 'Summary task'; fa = 'وظیفه خلاصه';
									|it = 'Task generale';
									|pl = 'Skonsolidowane zadanie';
									|tr = 'Görev özeti'");

	If AccessRight("Update", Metadata.Documents.JobForSalesRepresentative) Then
		// Setting up printing of task forms
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "PrintManagementTMClient.SettingUpPrintingOfTaskFormsToSalesRepresentative";
		PrintCommand.PrintManager = "";
		PrintCommand.Id = "ConfigureJobTemplatePrinting";
		PrintCommand.Presentation = NStr("vi = 'Tùy chỉnh in mẫu nhiệm vụ';
										|ru = 'Настройка печати бланков задания';
										|en = 'Task template print options'; fa = 'گزینه‌های چاپ الگوی وظیفه';
										|it = 'Impostazioni di stampa moduli dei task';
										|pl = 'Ustawienia druku formularzy zadania';
										|tr = 'Görev formlarının yazdırma ayarı'");
	EndIf;

EndProcedure

// Generates a printable form of objects.
//
// Parameters:
//   ObjectsArray - Array - Array of links to objects that need to be printed.
//   PrintParameters - Structure - Structure of additional print parameters.
//   PrintFormsCollection - ValueTable:
//    *TemplateName - String - layout name
//    *Copies2 - Number - number of instances
//    *UpperCaseName - String - the name is uppercase.
//   PrintObjects - ValueList - list of print objects.
//   OutputParameters - Structure - parameters of generated table documents.
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "JobTemplate") Then
		
		TaskFormLine = PrintFormsCollection.Find(Upper("JobTemplate"), "UpperCaseName");
		
		NewRow = PrintFormsCollection.Add();
		NewRow.TemplateName = "OrderTemplate";
		NewRow.Copies2 = TaskFormLine.Copies2;
		NewRow.UpperCaseName = Upper(NewRow.TemplateName);
		
		StructureOfForm = GetPrintedFormOfTaskForm(ObjectsArray, PrintObjects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection,
															"JobTemplate",
															NStr("vi = 'Nhiệm vụ';
																|ru = 'Задание';
																|en = 'Job'; fa = 'کار';
																|it = 'Task';
																|pl = 'Zadanie';
																|tr = 'İş'"),
															StructureOfForm.Job);
															
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection,
															"OrderTemplate",
															NStr("vi = 'Đơn hàng';
																|ru = 'Заказ';
																|en = 'Order'; fa = 'سفارش';
																|it = 'Ordine';
																|pl = 'Zamówienie';
																|tr = 'Sipariş'"),
															StructureOfForm.OrderDocument);
			
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "SummaryJob") Then
		
		SummaryJob = GetPrintedSummaryTaskForm(ObjectsArray, PrintObjects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection,
															"SummaryJob",
															NStr("vi = 'Nhiệm vụ tổng hợp';
																|ru = 'Сводное задание';
																|en = 'Summary task'; fa = 'وظیفه خلاصه';
																|it = 'Task generale';
																|pl = 'Skonsolidowane zadanie';
																|tr = 'Görev özeti'"),
															SummaryJob);
			
	EndIf;
		
EndProcedure

Function GetPrintedFormOfTaskForm(ObjectsArray, PrintObjects)
		
	JobTemplate = New SpreadsheetDocument();
	OrderTemplate = New SpreadsheetDocument();
	
	JobTemplate.PrintParametersKey = "PRINT_OPTIONS_JobForSalesRepresentative_JobTemplate";
	OrderTemplate.PrintParametersKey = "PRINT_OPTIONS_JobForSalesRepresentative_OrderTemplate";
	
	Query = New Query();
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.Text = GetRequestTextForCreatingPrintedFormOfTaskForm();
	
	ReportData = Query.Execute().Select();
	
	FirstDocument = True;
	StructureOfPrintParameters = GetJobPrintingSettings();
	
	While ReportData.Next() Do
		
		TaskFormTemplate = PrintManagement.PrintFormTemplate("Document.JobForSalesRepresentative.PF_MXL_JobTemplate");
		OrderFormTemplate = PrintManagement.PrintFormTemplate("Document.JobForSalesRepresentative.PF_MXL_OrderTemplate");
		
		If Not FirstDocument Then
			JobTemplate.PutHorizontalPageBreak();
			OrderTemplate.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		
		LineNumberStartOfForm = JobTemplate.TableHeight + 1;
		LineNumberStartOfFreightTrain = OrderTemplate.TableHeight + 1;

		// Output of the task form
		
		TemplateArea = TaskFormTemplate.GetArea("Header");
		
		DocumentTitle = TMCommonUseClientServer.GenerateDocumentTitle(
			ReportData, 
			NStr("vi = 'Nhiệm vụ dành cho đại diện thương mại';
				|ru = 'Задание торговому представителю';
				|en = 'Sales representative task'; fa = 'وظیفه نماینده فروش';
				|it = 'Task al rappresentante commerciale';
				|pl = 'Zadanie dla przedstawiciela handlowego';
				|tr = 'Satış temsilcisine görevler'", Common.DefaultLanguageCode()));
		TemplateArea.Parameters.TitleText = DocumentTitle;
		
		TemplateArea.Parameters.SalesRepresentative = ReportData.SalesRepresentative;
		TemplateArea.Parameters.Supervisor_ = ReportData.Supervisor_;
		TemplateArea.Parameters.SessionDate_ = Format(ReportData.PlannedVisitDate, "DLF=D");
		TemplateArea.Parameters.Opn = ?(ValueIsFilled(ReportData.BeginTime),Format(ReportData.BeginTime,"DF=hh:mm"),"____");
		TemplateArea.Parameters.Con = ?(ValueIsFilled(ReportData.EndTime),Format(ReportData.EndTime,"DF=hh:mm"),"____");
		
		Address = PrintFormGeneration.GetAddressFromContactInformation(ReportData.Partner);
		Phone = PrintFormGeneration.GetPhoneNumberFromContactInformation(ReportData.Partner);
		
		InformationOnPartner = TrimAll(ReportData.Partner) + ?(IsBlankString(Address),"", ", Address: " + Address) + ?(IsBlankString(Phone), "", ", Phone: " + Phone);
		
		TemplateArea.Parameters.InformationOnPartner = InformationOnPartner;
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(JobTemplate, TaskFormTemplate, TemplateArea, ReportData.Ref);
		JobTemplate.Put(TemplateArea);
		
		// Output of tasks defined in the task.
		
		If StructureOfPrintParameters.OutputTasks Then
			TaskTable_1 = ReportData.Tasks.Unload();
			
			If TaskTable_1.Count()>0 Then
				
				TemplateArea = TaskFormTemplate.GetArea("IsBlankString");
				JobTemplate.Put(TemplateArea);
			
				TemplateArea = TaskFormTemplate.GetArea("TasksHeader");
				JobTemplate.Put(TemplateArea);
				
				For Each TaskLine In TaskTable_1 Do
					TemplateArea = TaskFormTemplate.GetArea("TaskString");
					FillPropertyValues(TemplateArea.Parameters, TaskLine);
					JobTemplate.Put(TemplateArea);
				EndDo;
			EndIf;
		EndIf;
		
		// Output of the section of arbitrary notes of the sales representative.
		
		If StructureOfPrintParameters.DisplayNotes And StructureOfPrintParameters.NumberOfNoteLines > 0 Then
			
			TemplateArea = TaskFormTemplate.GetArea("IsBlankString");
			JobTemplate.Put(TemplateArea);
			
			TemplateArea = TaskFormTemplate.GetArea("NotesHeader");
			JobTemplate.Put(TemplateArea);
			
			OutputLines = 0;
			While OutputLines < StructureOfPrintParameters.NumberOfNoteLines Do
				TemplateArea = TaskFormTemplate.GetArea("NotesLine");
				JobTemplate.Put(TemplateArea);
				OutputLines = OutputLines + 1;
			EndDo;
		
		EndIf;
		
		// Order form output
		
		// Output of the order conditions defined in the task.
		
		TemplateArea = OrderFormTemplate.GetArea("Header");
		
		TemplateArea.Parameters.Partner = ReportData.Partner;
		TemplateArea.Parameters.Counterparty = ReportData.Counterparty;
		TemplateArea.Parameters.Currency = ReportData.Currency;
		
		If Not ReportData.ItemsDetails Then
			TemplateArea.Parameters.HeaderAmount = "Sum:";
			TemplateArea.Parameters.Sum = ReportData.SumPlan;
		EndIf;
		
		TemplateArea.Parameters.Warehouse = ReportData.Warehouse;
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(OrderTemplate, OrderFormTemplate, TemplateArea, ReportData.Ref);
		OrderTemplate.Put(TemplateArea);
		
		// Output of the payment schedule.
		
		If StructureOfPrintParameters.DisplayPaymentSchedule Then
			
			TableStagesOfPaymentSchedule = ReportData.PaymentScheduleSteps.Unload();
			
			If TableStagesOfPaymentSchedule.Count()>0 Or StructureOfPrintParameters.NumberOfPaymentScheduleLines>0 Then
				
				TemplateArea = OrderFormTemplate.GetArea("PaymentScheduleHeader_");
				OrderTemplate.Put(TemplateArea);
								
				If TableStagesOfPaymentSchedule.Count()>0 Then
					For Each LineStagesOfPaymentSchedule In TableStagesOfPaymentSchedule Do
						TemplateArea = OrderFormTemplate.GetArea("PaymentScheduleLine");
						FillPropertyValues(TemplateArea.Parameters, LineStagesOfPaymentSchedule);
						OrderTemplate.Put(TemplateArea);
					EndDo;
				Else
					OutputLines = 0;
					While OutputLines < StructureOfPrintParameters.NumberOfPaymentScheduleLines Do
						OutputLines = OutputLines + 1;
						TemplateArea = OrderFormTemplate.GetArea("PaymentScheduleLine");
						TemplateArea.Parameters.LineNumber = OutputLines;
						OrderTemplate.Put(TemplateArea);
					EndDo;
				EndIf;
			EndIf;
		EndIf;
				
		// Output of the product composition of the task.
		
		DiscountsAreUsed = GetFunctionalOption("UseDiscountAdjustmentsInSales");
		
		TemplateArea = OrderFormTemplate.GetArea("ProductsHeader_");
		OrderTemplate.Put(TemplateArea);

		TemplateArea = OrderFormTemplate.GetArea("ProductsHeader|LineNumber");
		OrderTemplate.Put(TemplateArea);
		
		ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
		NameOfCodeColumn = ColumnOfCodes.ColumnName;
		PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
		OutputCodes = ValueIsFilled(NameOfCodeColumn);
		
		If OutputCodes Then
			TemplateArea = OrderFormTemplate.GetArea("ProductsHeader|ColumnOfCodes");
			TemplateArea.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
			OrderTemplate.Join(TemplateArea);
		EndIf;
		
		If ReportData.ItemsDetails Then
			TemplateArea = OrderFormTemplate.GetArea("ProductsHeader|Products");
		Else
			TemplateArea = OrderFormTemplate.GetArea("ProductsHeader|ProductsWithoutPlan");
		EndIf;
		
		OrderTemplate.Join(TemplateArea);
				
		If ReportData.ItemsDetails Then
			TemplateArea = OrderFormTemplate.GetArea("ProductsHeader|CountPlan");
			OrderTemplate.Join(TemplateArea);
		EndIf;
		
		TemplateArea = OrderFormTemplate.GetArea("ProductsHeader|OrderData");
		OrderTemplate.Join(TemplateArea);
		
		If DiscountsAreUsed Then
			TemplateArea = OrderFormTemplate.GetArea("ProductsHeader|Discounts");
			OrderTemplate.Join(TemplateArea);
		EndIf;
		
		TemplateArea = OrderFormTemplate.GetArea("ProductsHeader|Comment");
		OrderTemplate.Join(TemplateArea);
		
		HeaderArea = OrderTemplate.Area(OrderTemplate.TableHeight, ,OrderTemplate.TableHeight, );
		OrderTemplate.RepeatOnRowPrint = HeaderArea;
		
		GoodsTable = ReportData.Goods.Unload();
		
		LineNumber = 0;
		For Each LineProducts_ In GoodsTable Do
			
			If Not PrintFormGeneration.CheckFillingInProducts(LineProducts_, LineProducts_.LineNumber) Then
				Continue;
			EndIf;
			
			LineNumber = LineNumber + 1;
			
			TemplateArea = OrderFormTemplate.GetArea("ProductsLine|LineNumber");
			TemplateArea.Parameters.LineNumber = LineNumber;
			OrderTemplate.Put(TemplateArea);
			
			If OutputCodes Then
				TemplateArea = OrderFormTemplate.GetArea("ProductsLine|ColumnOfCodes");
				TemplateArea.Parameters.SKU = LineProducts_[NameOfCodeColumn];
				OrderTemplate.Join(TemplateArea);
			EndIf;
			
			If ReportData.ItemsDetails Then
				TemplateArea = OrderFormTemplate.GetArea("ProductsLine|Products");
			Else
				TemplateArea = OrderFormTemplate.GetArea("ProductsLine|ProductsWithoutPlan");
			EndIf;
			
			AdditionalParametersForGettingNameToPrint = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersForGettingNameToPrint.Content = LineProducts_.Content;			
			AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			TemplateArea.Parameters.Products = ProductsClientServer.PresentationOfProductsForPrinting(
				LineProducts_.DescriptionFull,
				LineProducts_.Characteristic,
				, // Package
				, // Series
				AdditionalParametersForGettingNameToPrint);
			OrderTemplate.Join(TemplateArea);
			
			If ReportData.ItemsDetails Then
				TemplateArea = OrderFormTemplate.GetArea("ProductsLine|CountPlan");
				TemplateArea.Parameters.CountPlan = LineProducts_.CountPlan;
				OrderTemplate.Join(TemplateArea);
			EndIf;
			
			TemplateArea = OrderFormTemplate.GetArea("ProductsLine|OrderData");
			TemplateArea.Parameters.UnitOfMeasure = LineProducts_.UnitOfMeasure;
			TemplateArea.Parameters.Price = LineProducts_.Price;
			OrderTemplate.Join(TemplateArea);
			
			If DiscountsAreUsed Then
				TemplateArea = OrderFormTemplate.GetArea("ProductsLine|Discounts");
				OrderTemplate.Join(TemplateArea);
			EndIf;
			
			TemplateArea = OrderFormTemplate.GetArea("ProductsLine|Comment");
			TemplateArea.Parameters.Comment = TrimAll(LineProducts_.Comment);
			OrderTemplate.Join(TemplateArea);
			
		EndDo;
		
		// Addition of the table of goods with empty lines - for the possibility of specifying an unplanned product.
		
		OutputOfAdditionalLines = 0;
		
		While OutputOfAdditionalLines < StructureOfPrintParameters.NumberOfProductsLines Do
			
			LineNumber = LineNumber + 1;
			
			TemplateArea = OrderFormTemplate.GetArea("ProductsLine|LineNumber");
			TemplateArea.Parameters.LineNumber = LineNumber;
			OrderTemplate.Put(TemplateArea);
			
			If OutputCodes Then
				TemplateArea = OrderFormTemplate.GetArea("ProductsLine|ColumnOfCodes");
				OrderTemplate.Join(TemplateArea);
			EndIf;
			
			If ReportData.ItemsDetails Then
				TemplateArea = OrderFormTemplate.GetArea("ProductsLine|Products");
			Else
				TemplateArea = OrderFormTemplate.GetArea("ProductsLine|ProductsWithoutPlan");
			EndIf;
			
			OrderTemplate.Join(TemplateArea);
						
			If ReportData.ItemsDetails Then
				TemplateArea = OrderFormTemplate.GetArea("ProductsLine|CountPlan");
				OrderTemplate.Join(TemplateArea);
			EndIf;
			
			TemplateArea = OrderFormTemplate.GetArea("ProductsLine|OrderData");
			OrderTemplate.Join(TemplateArea);
			
			If DiscountsAreUsed Then
				TemplateArea = OrderFormTemplate.GetArea("ProductsLine|Discounts");
				OrderTemplate.Join(TemplateArea);
			EndIf;
			
			TemplateArea = OrderFormTemplate.GetArea("ProductsLine|Comment");
			OrderTemplate.Join(TemplateArea);
			
			OutputOfAdditionalLines = OutputOfAdditionalLines + 1;
		EndDo;
		
		TemplateArea = OrderFormTemplate.GetArea("Basement");
		OrderTemplate.Put(TemplateArea);
		
		If DiscountsAreUsed Then
			TemplateArea = OrderFormTemplate.GetArea("BasementDiscounts");
			OrderTemplate.Put(TemplateArea);
		EndIf;
		
		TemplateArea = OrderFormTemplate.GetArea("BasementSignature");
		OrderTemplate.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(JobTemplate, LineNumberStartOfForm, PrintObjects, ReportData.Ref);
		PrintManagement.SetDocumentPrintArea(OrderTemplate, LineNumberStartOfFreightTrain, PrintObjects, ReportData.Ref);
		
	EndDo;
	
	JobTemplate.Header.LeftText = DocumentTitle;
	JobTemplate.FitToPage = True;
	
	OrderTemplate.Header.LeftText = DocumentTitle;
	OrderTemplate.FitToPage = True;
	
	StructureOfForm = New Structure();
	StructureOfForm.Insert("Job", JobTemplate);
	StructureOfForm.Insert("OrderDocument", OrderTemplate);
	
	Return StructureOfForm;
	
EndFunction

Function GetPrintedSummaryTaskForm(ObjectsArray, PrintObjects)
		
	SummaryJob = New SpreadsheetDocument();
	SummaryJob.PrintParametersKey = "PrintPARAMETERS_SummaryTaskForSalesRepresentative";
	
	Query = New Query();
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.Text = GetRequestTextForCreatingPrintedSummaryTaskForm();
	
	ReportData = Query.Execute().Select();
	
	SummaryTaskTemplate = PrintManagement.PrintFormTemplate("Document.JobForSalesRepresentative.PF_MXL_SummaryJob");
	FirstDocument = True;
	CurSalesRepresentative = Undefined;
	
	StructureOfPrintParameters = GetJobPrintingSettings();
	
	LineNumber = 0;
	
	While ReportData.Next() Do
		
		If ReportData.SalesRepresentative <> CurSalesRepresentative Then
			
			If Not FirstDocument Then
				BringOutBasement(SummaryTaskTemplate, SummaryJob);
				WithdrawExpenses(SummaryTaskTemplate, SummaryJob, StructureOfPrintParameters);
				
				SummaryJob.PutHorizontalPageBreak();
			EndIf;
			
			LineNumberStartOfForm = SummaryJob.TableHeight + 1;
			LineNumber = 0;
			FirstDocument = False;
			
			TemplateArea = SummaryTaskTemplate.GetArea("Header");
			TemplateArea.Parameters.TitleText = NStr("vi = 'Tóm tắt đại diện bán hàng';
													|ru = 'Сводное задание торговому представителю';
													|en = 'Summary sales representative task'; fa = 'Summary sales representative task';
													|it = 'Task generale al rappresentante commerciale';
													|pl = 'Wolne zadanie przedstawicielu handlowemu';
													|tr = 'Satış temsilcisine görev özeti'", Common.DefaultLanguageCode());
			TemplateArea.Parameters.SalesRepresentative = ReportData.SalesRepresentative;
			BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SummaryJob, SummaryTaskTemplate, TemplateArea, ReportData.Ref);
			SummaryJob.Put(TemplateArea);
			
			TemplateArea = SummaryTaskTemplate.GetArea("PartnerHeader");
			SummaryJob.Put(TemplateArea);
			
			If StructureOfPrintParameters.OutputTasksInASummaryTask Then
				TemplateArea = SummaryTaskTemplate.GetArea("TasksHeader");
				SummaryJob.Put(TemplateArea);
			EndIf;
			
		EndIf;
		
		LineNumber = LineNumber + 1;
		
		TemplateArea = SummaryTaskTemplate.GetArea("PartnerString");
		TemplateArea.Parameters.LineNumber = LineNumber;
		TemplateArea.Parameters.Date = Format(ReportData.PlannedVisitDate, "DLF=D");
		
		If ValueIsFilled(ReportData.BeginTime) Then
			Time = Format(ReportData.BeginTime,"DF=hh:mm") + ?(ValueIsFilled(ReportData.EndTime),"-" + Format(ReportData.EndTime,"DF=hh:mm"),"");
		Else
			Time = "";
		EndIf;
		TemplateArea.Parameters.Time = Time;
		
		Address = PrintFormGeneration.GetAddressFromContactInformation(ReportData.Partner);
		Phone = PrintFormGeneration.GetPhoneNumberFromContactInformation(ReportData.Partner);
		
		InformationOnPartner = TrimAll(ReportData.Partner) + ?(IsBlankString(Address),"", ", Address: " + Address) + ?(IsBlankString(Phone), "", ", Phone: " + Phone);
		
		TemplateArea.Parameters.InformationOnPartner = InformationOnPartner;
		SummaryJob.Put(TemplateArea);
		
		If StructureOfPrintParameters.OutputTasksInASummaryTask Then
			// Output of tasks defined in the task.
			TaskTable_1 = ReportData.Tasks.Unload();
			
			For Each TaskLine In TaskTable_1 Do
				TemplateArea = SummaryTaskTemplate.GetArea("TaskString");
				TemplateArea.Parameters.TaskDetails1 = TaskLine.TaskDetails1;
				SummaryJob.Put(TemplateArea);
			EndDo;
		EndIf;
		
		CurSalesRepresentative = ReportData.SalesRepresentative;
		
		PrintManagement.SetDocumentPrintArea(SummaryJob, LineNumberStartOfForm, PrintObjects, ReportData.Ref);
		
	EndDo;
		
	BringOutBasement(SummaryTaskTemplate, SummaryJob);
	WithdrawExpenses(SummaryTaskTemplate, SummaryJob, StructureOfPrintParameters);
		
	SummaryJob.FitToPage = True;
	
	Return SummaryJob;
	
EndFunction

// Displays a section of the basement.
//
// Parameters:
//  Template - SpreadsheetDocument - the layout that the tabular document is based on.
//  SpreadsheetDocument - SpreadsheetDocument -the final tabular document that the section is displayed in.
//
Procedure BringOutBasement(Template, SpreadsheetDocument)
	
	TemplateArea = Template.GetArea("Footer");
	CellArea = SpreadsheetDocument.Put(TemplateArea);
	CellArea.RowHeight = 1;
	
EndProcedure

// Displays the expense section.
//
// Parameters:
//  Template - SpreadsheetDocument - the layout that the tabular document is based on.
//  SpreadsheetDocument - SpreadsheetDocument - the final tabular document that the section is displayed in.
//  StructureOfPrintParameters - Structure - a structure containing the print settings.
//
Procedure WithdrawExpenses(Template, SpreadsheetDocument, StructureOfPrintParameters)
	
	If StructureOfPrintParameters.DisplayExpenses And StructureOfPrintParameters.NumberOfExpenseLines > 0 Then
		
		TemplateArea = Template.GetArea("IsBlankString");
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("ExpensesCap");
		SpreadsheetDocument.Put(TemplateArea);
		
		OutputLines = 0;
		While OutputLines < StructureOfPrintParameters.NumberOfExpenseLines Do
			TemplateArea = Template.GetArea("ExpensesLine");
			TemplateArea.Parameters.LineNumber = OutputLines + 1;
			SpreadsheetDocument.Put(TemplateArea);
			OutputLines = OutputLines + 1;
		EndDo;
		
	EndIf;
	
EndProcedure

Function GetRequestTextForCreatingPrintedFormOfTaskForm()
	
	QueryText = 
	"SELECT ALLOWED
	|	JobForSalesRepresentative.Ref AS Ref,
	|	JobForSalesRepresentative.Number AS Number,
	|	JobForSalesRepresentative.Date AS Date,
	|	JobForSalesRepresentative.Organization AS Organization,
	|	JobForSalesRepresentative.Organization.Prefix AS Prefix,
	|	JobForSalesRepresentative.Partner AS Partner,
	|	JobForSalesRepresentative.Counterparty AS Counterparty,
	|	JobForSalesRepresentative.PlannedVisitDate AS PlannedVisitDate,
	|	JobForSalesRepresentative.BeginTime AS BeginTime,
	|	JobForSalesRepresentative.EndTime AS EndTime,
	|	JobForSalesRepresentative.PriceIncludesVAT AS PriceIncludesVAT,
	|	JobForSalesRepresentative.Currency AS Currency,
	|	JobForSalesRepresentative.SumPlan AS SumPlan,
	|	JobForSalesRepresentative.SalesRepresentative AS SalesRepresentative,
	|	JobForSalesRepresentative.Supervisor_ AS Supervisor_,
	|	JobForSalesRepresentative.Warehouse AS Warehouse,
	|	JobForSalesRepresentative.ItemsDetails,
	|	JobForSalesRepresentative.Goods.(
	|		LineNumber AS LineNumber,
	|		Products AS Products,
	|		Products.DescriptionFull AS DescriptionFull,
	|		CASE
	|			WHEN JobForSalesRepresentative.Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN JobForSalesRepresentative.Goods.Products.UnitOfMeasure.Description
	|			ELSE JobForSalesRepresentative.Goods.Package.Description
	|		END AS UnitOfMeasure,
	|		CountPlan AS CountPlan,
	|		Price AS Price,
	|		Characteristic.DescriptionFull AS Characteristic,
	|		Comment AS Comment,
	|		Products.Code AS Code,
	|		Products.SKU AS SKU,
	|		Content AS Content
	|	),
	|	JobForSalesRepresentative.Tasks.(
	|		LineNumber,
	|		TaskDetails1
	|	),
	|	JobForSalesRepresentative.PaymentScheduleSteps.(
	|		LineNumber AS LineNumber,
	|		PaymentOption,
	|		PaymentDate,
	|		PaymentPercentage
	|	),
	|	Constants.UseItemVariants AS CharacteristicsUsed
	|FROM
	|	Document.JobForSalesRepresentative AS JobForSalesRepresentative
	|		LEFT JOIN Constants AS Constants
	|		ON (TRUE)
	|WHERE
	|	JobForSalesRepresentative.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref";
	
	Return QueryText;
	
EndFunction

Function GetRequestTextForCreatingPrintedSummaryTaskForm()
	
	QueryText = 
	"SELECT ALLOWED
	|	JobForSalesRepresentative.Ref AS Ref,
	|	JobForSalesRepresentative.Number AS Number,
	|	JobForSalesRepresentative.Date AS Date,
	|	JobForSalesRepresentative.Partner AS Partner,
	|	JobForSalesRepresentative.PlannedVisitDate AS PlannedVisitDate,
	|	JobForSalesRepresentative.BeginTime AS BeginTime,
	|	JobForSalesRepresentative.EndTime AS EndTime,
	|	JobForSalesRepresentative.SalesRepresentative AS SalesRepresentative,
	|	JobForSalesRepresentative.Tasks.(
	|		TaskDetails1
	|	)
	|FROM
	|	Document.JobForSalesRepresentative AS JobForSalesRepresentative
	|WHERE
	|	JobForSalesRepresentative.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	SalesRepresentative,
	|	PlannedVisitDate,
	|	BeginTime";
	
	Return QueryText;
	
EndFunction

// Returns the print settings for the task form.
//
// Returns:
//  Structure - the structure containing the settings for printing the form.
//
Function GetJobPrintingSettings()
	
	FormPrintingSettings = New Structure();
	
	FormPrintingSettings.Insert("OutputTasksInASummaryTask", False);
	FormPrintingSettings.Insert("DisplayPaymentSchedule", True);
	FormPrintingSettings.Insert("OutputTasks", True);
	FormPrintingSettings.Insert("DisplayExpenses", True);
	FormPrintingSettings.Insert("DisplayNotes", True);
	FormPrintingSettings.Insert("NumberOfPaymentScheduleLines", 3);
	FormPrintingSettings.Insert("NumberOfProductsLines", 5);
	FormPrintingSettings.Insert("NumberOfExpenseLines", 5);
	FormPrintingSettings.Insert("NumberOfNoteLines", 5);
	
	SetParameterValuesFromSettings(FormPrintingSettings);
	
	Return FormPrintingSettings;

EndFunction

// Sets the values of the print settings.
//
// Parameters:
//  StructureOfPrintSettings - Structure - a structure containing the print settings.
//
Procedure SetParameterValuesFromSettings(StructureOfPrintSettings)
	
	For Each StructureItem In StructureOfPrintSettings Do
		ParameterName = StructureItem.Key;
		ParameterValue = Common.CommonSettingsStorageLoad("Document.JobForSalesRepresentative.SettingsForPrintingTaskForms", ParameterName);
		
		If ParameterValue <> Undefined Then
			StructureOfPrintSettings[ParameterName] = ParameterValue;
		EndIf;
	EndDo;

EndProcedure

// Called when filling in current cases.
//
// Parameters:
//  ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = "Document.JobForSalesRepresentative.Form.ListForm";
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user.
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.JobForSalesRepresentative))
		And (AccessRight("Insert", Metadata.Documents.JobForSalesRepresentative)
			Or AccessRight("Update", Metadata.Documents.JobForSalesRepresentative))
		And GetFunctionalOption("UseJobsToManageSalesRepresentatives");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(DISTINCT CASE
	|			WHEN JobForSalesRepresentative.Status = VALUE(Enum.SalesRepresentativeTaskStatuses.NotPrepared2)
	|				THEN JobForSalesRepresentative.Ref
	|		END) AS TasksForSalesRepresentativesToPrepare,
	|	COUNT(DISTINCT CASE
	|			WHEN JobForSalesRepresentative.Status = VALUE(Enum.SalesRepresentativeTaskStatuses.NotPrepared2)
	|					AND JobForSalesRepresentative.PlannedVisitDate < BEGINOFPERIOD(&UpdateDate, DAY)
	|				THEN JobForSalesRepresentative.Ref
	|			WHEN JobForSalesRepresentative.Status = VALUE(Enum.SalesRepresentativeTaskStatuses.ToProcessing)
	|					AND JobForSalesRepresentative.PlannedVisitDate < BEGINOFPERIOD(&UpdateDate, DAY)
	|					AND JobForSalesRepresentative.ActualVisitDate = DATETIME(1, 1, 1)
	|				THEN JobForSalesRepresentative.Ref
	|		END) AS OverdueSalesRepresentativeAssignments,
	|	COUNT(DISTINCT CASE
	|			WHEN SalesOrder.DocumentBasis IS NULL 
	|					AND JobForSalesRepresentative.Status = VALUE(Enum.SalesRepresentativeTaskStatuses.Processed_)
	|				THEN JobForSalesRepresentative.Ref
	|		END) AS TasksForSalesRepresentativesToPlaceOrders
	|FROM
	|	Document.JobForSalesRepresentative AS JobForSalesRepresentative
	|		LEFT JOIN Document.SalesOrder AS SalesOrder
	|		ON JobForSalesRepresentative.Ref = SalesOrder.DocumentBasis
	|WHERE
	|	JobForSalesRepresentative.Supervisor_ = &User
	|	AND (NOT JobForSalesRepresentative.DeletionMark)";
	
	Result = ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	// Tasks for Trade representatives
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "TasksForSalesRepresentatives";
	UserTaskParent.Presentation  = NStr("vi = 'Nhiệm vụ đối với đại diện thương mại';
										|ru = 'Задания торговым представителям';
										|en = 'Sales representative tasks'; fa = 'وظایف نماینده فروش';
										|it = 'Task ai rappresentanti commerciali';
										|pl = 'Zadania dla przedstawicieli handlowych';
										|tr = 'Satış temsilcisinin görevleri'");
	UserTaskParent.Owner       = Metadata.Subsystems.Sales;
	
	// TasksForSalesRepresentativesToPrepare
	FilterParameters = New Structure;
	FilterParameters.Insert("Status", Enums.SalesRepresentativeTaskStatuses.NotPrepared2);
	FilterParameters.Insert("Supervisor_", CommonQueryParameters.User);
	FilterParameters.Insert("Relevance", "");
	FilterParameters.Insert("PresenceOfOrders", "");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "TasksForSalesRepresentativesToPrepare";
	ToDoItem.HasToDoItems       = Result.TasksForSalesRepresentativesToPrepare > 0;
	ToDoItem.Presentation  = NStr("vi = 'Nhiệm vụ cần soạn';
									|ru = 'Задания к подготовке';
									|en = 'Jobs for preparation'; fa = 'Jobs for preparation';
									|it = 'Task per preparazione';
									|pl = 'Zadanie do przygotowania';
									|tr = 'Hazırlık görevleri'");
	ToDoItem.Count     = Result.TasksForSalesRepresentativesToPrepare;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "TasksForSalesRepresentatives";
	
	// TasksForSalesRepresentativesToPlaceOrders
	FilterParameters = New Structure;
	FilterParameters.Insert("Status", Enums.SalesRepresentativeTaskStatuses.Processed_);
	FilterParameters.Insert("Supervisor_", CommonQueryParameters.User);
	FilterParameters.Insert("Relevance", "");
	FilterParameters.Insert("PresenceOfOrders", "Orders not decorated");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "TasksForSalesRepresentativesToPlaceOrders";
	ToDoItem.HasToDoItems       = Result.TasksForSalesRepresentativesToPlaceOrders > 0;
	ToDoItem.Presentation  = NStr("vi = 'Nhiệm vụ cần lập đơn hàng';
									|ru = 'Задания к оформлению заказов';
									|en = 'Job for order registration'; fa = 'Job for order registration';
									|it = 'Task per formalizzazione ordini';
									|pl = 'Zadania do sporządzenia zamówień';
									|tr = 'Sipariş düzenleme görevleri'");
	ToDoItem.Count     = Result.TasksForSalesRepresentativesToPlaceOrders;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "TasksForSalesRepresentatives";
	
	// OverdueSalesRepresentativeAssignments
	FilterParameters = New Structure;
	FilterParameters.Insert("Status", Enums.SalesRepresentativeTaskStatuses.EmptyRef());
	FilterParameters.Insert("Supervisor_", CommonQueryParameters.User);
	FilterParameters.Insert("Relevance", "Overdue1");
	FilterParameters.Insert("PresenceOfOrders", "");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "OverdueSalesRepresentativeAssignments";
	ToDoItem.HasToDoItems       = Result.OverdueSalesRepresentativeAssignments > 0;
	ToDoItem.Presentation  = NStr("vi = 'Nhiệm vụ quá hạn';
									|ru = 'Просроченные задания';
									|en = 'Overdue jobs'; fa = 'Overdue jobs';
									|it = 'Task scaduti';
									|pl = 'Zaległe zadani';
									|tr = 'Geçmiş görevler'");
	ToDoItem.Count     = Result.OverdueSalesRepresentativeAssignments;
	ToDoItem.Important         = True;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "TasksForSalesRepresentatives";
	
	If Result.TasksForSalesRepresentativesToPrepare > 0
		Or Result.TasksForSalesRepresentativesToPlaceOrders > 0
		Or Result.OverdueSalesRepresentativeAssignments > 0 Then
		UserTaskParent.HasToDoItems = True;
	EndIf;
	
EndProcedure

// Returns a table of settlement amounts broken down by container/non-container and broken down by order.
// 
// Parameters:
//  ObjectReference_ - DocumentRef.JobForSalesRepresentative - The document for which you want to get the data.
//  AttributesValues - Structure
// 
// Returns:
//  ValueTable - ValueTable:
// 		* OrderDocument - DocumentRef - OrderDocument
// 		* Date - Date - Document date
// 		* ApprovalDate - Date - Approval date (for orders)
// 		* DateOfShipment - Date - Scheduled shipment date
// 		* AmountARAP - Number - Amount Of Settlements By Line
// 		* AmountARAPByPackage - Number - The amount of settlements by container by line
Function OrderAmounts(ObjectReference_, AttributesValues = Undefined) Export
	
	Query = New Query;
	
	Query.Text = "
	|SELECT
	|	Goods.AmountIncludingVAT           AS Sum,
	|	CAST(Goods.Products AS Catalog.Products)        AS Products,
	|	Goods.CancellationReason       AS CancellationReason,
	|	&ToReturnReusablePackage AS ToReturnReusablePackage,
	|	&PackageDepositIsRequired      AS PackageDepositIsRequired
	|INTO TTProducts_1
	|FROM &ValueTable AS Goods
	|WHERE &LinkCondition_
	|;
	|SELECT 
	|	UNDEFINED                                     AS OrderDocument,
	|	DATETIME(1,1,1)                                 AS OrderDate,
	|	DATETIME(1,1,1)                                 AS ApprovalDate,
	|	FALSE                                             AS ExceedingOrder,
	|	SUM(NestedQuery.PaymentAmount)              AS PaymentAmount,
	|	0                                                AS AmountARAP,
	|	SUM(NestedQuery.PackageDepositValue)         AS PackageDepositValue,
	|	0                                                AS AmountARAPByPackage
	|FROM (SELECT
	|		CASE
	|			WHEN Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|					OR NOT Goods.ToReturnReusablePackage
	|				THEN Goods.Sum
	|			ELSE 0 
	|		END                             AS PaymentAmount,
	|		CASE 
	|			WHEN Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND Goods.PackageDepositIsRequired
	|				THEN Goods.Sum
	|			ELSE 0 
	|		END                            AS PackageDepositValue
	|	FROM TTProducts_1 AS Goods
	|	WHERE Goods.CancellationReason = VALUE(Catalog.ReasonsForSaleOrderCancellation.EmptyRef)) AS NestedQuery
	|;";
	
	If AttributesValues = Undefined Then
		Query.Text = StrReplace(Query.Text, "&ValueTable", "Document.JobForSalesRepresentative.Goods");
		Query.Text = StrReplace(Query.Text, "&ToReturnReusablePackage", "Goods.Ref.ToReturnReusablePackage");
		Query.Text = StrReplace(Query.Text, "&PackageDepositIsRequired", "Goods.Ref.PackageDepositIsRequired");
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "Goods.Ref = &Ref");
		Query.SetParameter("Ref",ObjectReference_);
	Else
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "TRUE");
		For Each KeyValue In AttributesValues Do
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#EndIf
