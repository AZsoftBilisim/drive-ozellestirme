#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	ReportSettings = ThisForm.ReportSettings;
	
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//   For example, if the report schema depends on the option key or report parameters.
//   For schema changes to take effect, call the ReportServer method.Connect the circuit().
//
// Parameters:
//   Context - Arbitrary - 
//       Parameters of the context in which the report is used.
//       Used for passing the ReportServer method parameters.Connect the circuit().
//   SchemaKey - String -
//       ID of the current configuration Builder schema.
//       By default, it is empty (this means that the linker is initialized based on the main schema).
//       Used for optimization to reinitialize the linker as rarely as possible).
//       It may not be used if reinitialization is performed unconditionally.
//   VariantKey - String, Undefined -
//       Name of the predefined or unique ID of the custom version of the report.
//       Undefined when calling for a decryption option or without context.
//   NewDCSettings - DataCompositionSettings, Undefined -
//       Report variant settings that will be loaded into the settings Builder after it is initialized.
//       Undefined when the option settings do not need to be loaded (already loaded earlier).
//   NewDCUserSettings - DataCompositionUserSettings, Undefined -
//       User settings that will be loaded into the Settings Composer after it is initialized.
//       It is uncertain when user settings do not need to be loaded (already loaded earlier).
//
// Examples:
// 1. The Composer of the report is initialized based on the scheme from the general Templates:
//	If the key of the scheme <> is "1" Then
//		Schema Key = "1";
//		SCHEMACD = Get a Public package("My Public Schemacompositions");
//		Server report.Connect a schema(This is an Object, Context, Schema, Schema Key);
//	The end if;
//
// 2. The scheme depends on the value of the parameter displayed in the user settings of the report:
//	If the type of ID is(New usersenastroykid) = Type("Custom setups of Data components") Then
//		Full Data objectName = "";
//		For Each Cd element From The New Userenastroykid.Elements of the Cycle
//			If the type of ID is (CD element) = Type("Parameter setter values") Then
//				Parameter Name = String(element).Parameter);
//				If Parameter Name = "Data objectmethod" Then
//					Full Data objectName = Data element.Value;
//				The end if;
//			The end if;
//		The end of the cycle;
//		If the Schema key <> is the full Data objectName, then
//			Schema Key = Full Data objectname;
//			Schemacd = New schemacomposedata;
//			Filling in the schema...
//			Server report.Connect a schema(This is an Object, Context, Schema, Schema Key);
//		The end if;
//	The end if;
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
			
EndProcedure

#EndRegion
	
#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);
	
	DataCompositionSchema.DataSets.DataSet.Query = QueryText();
	
	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();

	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetRequiredSettings(UserSettingsModified)
		
	// String literals
	DataCompositionClientServer.SetParameter(SettingsComposer, "StatusLineHasBeenCompleted", NStr("vi = 'Đã kết chuyển';
																									|ru = 'Проведен';
																									|en = 'Posted'; fa = 'ثبت‌شده';
																									|it = 'Registrato';
																									|pl = 'Posted';
																									|tr = 'Kaydedildi'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "StateLineIsNotPassed", NStr("vi = 'Chưa kết chuyển';
																							|ru = 'Не проведен';
																							|en = 'Not posted'; fa = 'Not posted';
																							|it = 'Non pubblicato';
																							|pl = 'Nie zatwierdzony';
																							|tr = 'Onaylanmadı'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "StateLineMarkedForDeletion", NStr("vi = 'Đã đánh dấu xóa';
																									|ru = 'Помечен на удаление';
																									|en = 'Marked for deletion'; fa = 'Marked for deletion';
																									|it = 'Contrassegnato per l''eliminazione';
																									|pl = 'Zaznaczony do usunięcia';
																									|tr = 'Silinmek üzere işaretlendi'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineNoSalesReport", NStr("vi = 'Không có bảng kê bán hàng';
																						|ru = 'Нет отчета о продажах';
																						|en = 'No sales report'; fa = 'No sales report';
																						|it = 'Non vi sono report sulle vendite';
																						|pl = 'Brak raportów o sprzedaży';
																						|tr = 'Satışlara ilişkin rapor yok'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineNoRefundReport", NStr("vi = 'Không có bảng kê trả lại';
																							|ru = 'Нет отчета о возвратах';
																							|en = 'No return report'; fa = 'No return report';
																							|it = 'Non vi sono report sui resi';
																							|pl = 'Brak raportu o zwrotach';
																							|tr = 'İadelere ilişkin rapor yok'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineCashShiftExpectedToClose", NStr("vi = 'Đang chờ đóng phiên thu ngân';
																									|ru = 'Ожидается закрытие кассовой смены';
																									|en = 'POS shift closing is expected'; fa = 'POS shift closing is expected';
																									|it = 'Si attende la chiusura del turno di cassa';
																									|pl = 'Oczekuje się zamknięcie zmiany kasowej';
																									|tr = 'Kasa vardiyası kapanışı bekleniyor'"));
		
EndProcedure

Function QueryText()
	
	QueryText = "SELECT DISTINCT
	               |	CashRegisterReceipt.CashRegisterShift AS CashRegisterShift,
	               |	CashRegisterReceipt.VATTaxation AS VATTaxation,
	               |	CashRegisterReceipt.VATTaxation AS CashRegisterReceiptVATTaxation,
	               |	FALSE AS ThereIsConductedSalesReport,
	               |	FALSE AS ThereIsReportOnRefunds
	               |INTO PreliminaryDataOnVATTaxation
	               |FROM
	               |	Document.CashRegisterShift AS DocumentCashRegisterShift
	               |		INNER JOIN Document.CashRegisterReceipt AS CashRegisterReceipt
	               |		ON DocumentCashRegisterShift.Ref = CashRegisterReceipt.CashRegisterShift
	               |WHERE
	               |	CashRegisterReceipt.Posted
	               |	AND CashRegisterReceipt.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	               |{WHERE
	               |	(DocumentCashRegisterShift.Organization = &Organization),
	               |	(DocumentCashRegisterShift.CashRegister = &CashRegister),
	               |	(DocumentCashRegisterShift.CashRegister.Warehouse = &Warehouse),
	               |	(DocumentCashRegisterShift.Date >= &BeginOfPeriod),
	               |	(DocumentCashRegisterShift.Date <= &EndOfPeriod)}
	               |
	               |UNION ALL
	               |
	               |SELECT DISTINCT
	               |	ReceiptOfCashRegisterAdjustment.CashRegisterShift,
	               |	ReceiptOfCashRegisterAdjustment.VATTaxation,
	               |	CASE
	               |		WHEN ReceiptOfCashRegisterAdjustment.CashRegisterReceipt = VALUE(Document.CashRegisterReceipt.EmptyRef)
	               |			THEN ReceiptOfCashRegisterAdjustment.VATTaxation
	               |		ELSE ReceiptOfCashRegisterAdjustment.CashRegisterReceipt.VATTaxation
	               |	END,
	               |	FALSE,
	               |	FALSE
	               |FROM
	               |	Document.CashRegisterShift AS DocumentCashRegisterShift
	               |		INNER JOIN Document.ReceiptOfCashRegisterAdjustment AS ReceiptOfCashRegisterAdjustment
	               |		ON DocumentCashRegisterShift.Ref = ReceiptOfCashRegisterAdjustment.CashRegisterShift
	               |WHERE
	               |	ReceiptOfCashRegisterAdjustment.Posted
	               |	AND ReceiptOfCashRegisterAdjustment.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	               |{WHERE
	               |	(DocumentCashRegisterShift.Organization = &Organization),
	               |	(DocumentCashRegisterShift.CashRegister = &CashRegister),
	               |	(DocumentCashRegisterShift.CashRegister.Warehouse = &Warehouse),
	               |	(DocumentCashRegisterShift.Date >= &BeginOfPeriod),
	               |	(DocumentCashRegisterShift.Date <= &EndOfPeriod)}
	               |
	               |UNION ALL
	               |
	               |SELECT DISTINCT
	               |	CashRegisterReceiptReturn.CashRegisterShift,
	               |	CashRegisterReceiptReturn.VATTaxation,
	               |	CASE
	               |		WHEN CashRegisterReceiptReturn.CashRegisterReceipt = VALUE(Document.CashRegisterReceipt.EmptyRef)
	               |			THEN CashRegisterReceiptReturn.VATTaxation
	               |		ELSE CashRegisterReceiptReturn.CashRegisterReceipt.VATTaxation
	               |	END,
	               |	FALSE,
	               |	FALSE
	               |FROM
	               |	Document.CashRegisterShift AS DocumentCashRegisterShift
	               |		INNER JOIN Document.CashRegisterReceiptReturn AS CashRegisterReceiptReturn
	               |		ON DocumentCashRegisterShift.Ref = CashRegisterReceiptReturn.CashRegisterShift
	               |WHERE
	               |	CashRegisterReceiptReturn.Posted
	               |	AND CashRegisterReceiptReturn.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	               |{WHERE
	               |	(DocumentCashRegisterShift.Organization = &Organization),
	               |	(DocumentCashRegisterShift.CashRegister = &CashRegister),
	               |	(DocumentCashRegisterShift.CashRegister.Warehouse = &Warehouse),
	               |	(DocumentCashRegisterShift.Date >= &BeginOfPeriod),
	               |	(DocumentCashRegisterShift.Date <= &EndOfPeriod)}
	               |
	               |UNION ALL
	               |
	               |SELECT DISTINCT
	               |	RetailSalesReport.CashRegisterShift,
	               |	RetailSalesReport.VATTaxation,
	               |	RetailSalesReport.VATTaxation,
	               |	TRUE,
	               |	FALSE
	               |FROM
	               |	Document.CashRegisterShift AS DocumentCashRegisterShift
	               |		INNER JOIN Document.RetailSalesReport AS RetailSalesReport
	               |		ON DocumentCashRegisterShift.Ref = RetailSalesReport.CashRegisterShift
	               |WHERE
	               |	RetailSalesReport.Posted
	               |{WHERE
	               |	(DocumentCashRegisterShift.Organization = &Organization),
	               |	(DocumentCashRegisterShift.CashRegister = &CashRegister),
	               |	(DocumentCashRegisterShift.CashRegister.Warehouse = &Warehouse),
	               |	(DocumentCashRegisterShift.Date >= &BeginOfPeriod),
	               |	(DocumentCashRegisterShift.Date <= &EndOfPeriod)}
	               |
	               |UNION ALL
	               |
	               |SELECT DISTINCT
	               |	RetailReturnsReport.CashRegisterShift,
	               |	RetailReturnsReport.VATTaxation,
	               |	RetailReturnsReport.VATTaxation,
	               |	FALSE,
	               |	TRUE
	               |FROM
	               |	Document.CashRegisterShift AS DocumentCashRegisterShift
	               |		INNER JOIN Document.RetailReturnsReport AS RetailReturnsReport
	               |		ON DocumentCashRegisterShift.Ref = RetailReturnsReport.CashRegisterShift
	               |WHERE
	               |	RetailReturnsReport.Posted
	               |{WHERE
	               |	(DocumentCashRegisterShift.Organization = &Organization),
	               |	(DocumentCashRegisterShift.CashRegister = &CashRegister),
	               |	(DocumentCashRegisterShift.CashRegister.Warehouse = &Warehouse),
	               |	(DocumentCashRegisterShift.Date >= &BeginOfPeriod),
	               |	(DocumentCashRegisterShift.Date <= &EndOfPeriod)}
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	Data.CashRegisterShift AS CashRegisterShift,
	               |	Data.VATTaxation AS VATTaxation,
	               |	MAX(Data.ThereIsConductedSalesReport) AS ThereIsConductedSalesReport,
	               |	MAX(Data.ThereIsReportOnRefunds) AS ThereIsReportOnRefunds
	               |INTO CashShiftsVATTaxation
	               |FROM
	               |	(SELECT
	               |		PreliminaryData.CashRegisterShift AS CashRegisterShift,
	               |		PreliminaryData.VATTaxation AS VATTaxation,
	               |		PreliminaryData.ThereIsConductedSalesReport AS ThereIsConductedSalesReport,
	               |		PreliminaryData.ThereIsReportOnRefunds AS ThereIsReportOnRefunds
	               |	FROM
	               |		PreliminaryDataOnVATTaxation AS PreliminaryData
	               |	
	               |	UNION
	               |	
	               |	SELECT
	               |		PreliminaryData.CashRegisterShift,
	               |		PreliminaryData.CashRegisterReceiptVATTaxation,
	               |		PreliminaryData.ThereIsConductedSalesReport,
	               |		PreliminaryData.ThereIsReportOnRefunds
	               |	FROM
	               |		PreliminaryDataOnVATTaxation AS PreliminaryData) AS Data
	               |
	               |GROUP BY
	               |	Data.CashRegisterShift,
	               |	Data.VATTaxation
				   |
				   |INDEX BY CashRegisterShift, VATTaxation
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	DocumentCashRegisterShift.Ref AS CashRegisterShift,
	               |	DocumentCashRegisterShift.Organization AS Organization,
	               |	DocumentCashRegisterShift.Status AS ShiftState,
	               |	DocumentCashRegisterShift.CashRegister.Warehouse AS Warehouse,
	               |	DocumentCashRegisterShift.CashRegister AS CashRegister,
	               |	CashShiftsVATTaxation.VATTaxation AS VATTaxation,
	               |	ISNULL(RetailSalesReport.Ref, UNDEFINED) AS SalesReturnsReport,
	               |	CASE
	               |		WHEN DocumentCashRegisterShift.Status = VALUE(Enum.CashRegisterShiftStatuses.IsOpen)
	               |			THEN &LineCashShiftExpectedToClose				   
	               |		WHEN RetailSalesReport.Posted IS NULL
	               |			THEN &LineNoSalesReport
	               |		WHEN RetailSalesReport.Posted
	               |			THEN &StatusLineHasBeenCompleted
	               |		WHEN RetailSalesReport.DeletionMark
	               |			THEN &StateLineMarkedForDeletion				   
	               |		ELSE &StateLineIsNotPassed
	               |	END AS StateOfSalesReturnsReport
	               |FROM
	               |	Document.CashRegisterShift AS DocumentCashRegisterShift
	               |		LEFT JOIN CashShiftsVATTaxation AS CashShiftsVATTaxation
	               |		ON (CashShiftsVATTaxation.CashRegisterShift = DocumentCashRegisterShift.Ref)
	               |		LEFT JOIN Document.RetailSalesReport AS RetailSalesReport
	               |		ON (RetailSalesReport.CashRegisterShift = DocumentCashRegisterShift.Ref)
	               |			AND (RetailSalesReport.VATTaxation = CashShiftsVATTaxation.VATTaxation)
				   |WHERE
				   |	CASE
				   |			WHEN CashShiftsVATTaxation.ThereIsConductedSalesReport IS NULL
				   |				THEN TRUE
				   |			ELSE CASE
				   |					WHEN CashShiftsVATTaxation.ThereIsConductedSalesReport
				   |						THEN ISNULL(RetailSalesReport.Posted, TRUE)
				   |					ELSE TRUE
				   |				END
				   |		END
	               |{WHERE
	               |	(DocumentCashRegisterShift.Organization = &Organization),
	               |	(DocumentCashRegisterShift.CashRegister = &CashRegister),
	               |	(DocumentCashRegisterShift.CashRegister.Warehouse = &Warehouse),
	               |	(DocumentCashRegisterShift.Date >= &BeginOfPeriod),
	               |	(DocumentCashRegisterShift.Date <= &EndOfPeriod)}
				   |
				   |UNION ALL
				   |
	               |SELECT
	               |	DocumentCashRegisterShift.Ref AS CashRegisterShift,
	               |	DocumentCashRegisterShift.Organization AS Organization,
	               |	DocumentCashRegisterShift.Status AS ShiftState,
	               |	DocumentCashRegisterShift.CashRegister.Warehouse AS Warehouse,
	               |	DocumentCashRegisterShift.CashRegister AS CashRegister,
	               |	CashShiftsVATTaxation.VATTaxation AS VATTaxation,
	               |	ISNULL(RetailReturnsReport.Ref, UNDEFINED) AS SalesReturnsReport,
	               |	CASE
	               |		WHEN DocumentCashRegisterShift.Status = VALUE(Enum.CashRegisterShiftStatuses.IsOpen)
	               |			THEN &LineCashShiftExpectedToClose
	               |		WHEN RetailReturnsReport.Posted IS NULL
	               |			THEN &LineNoRefundReport
	               |		WHEN RetailReturnsReport.Posted
	               |			THEN &StatusLineHasBeenCompleted
	               |		WHEN RetailReturnsReport.DeletionMark
	               |			THEN &StateLineMarkedForDeletion				   
	               |		ELSE &StateLineIsNotPassed
	               |	END AS StateOfSalesReturnsReport
	               |FROM
	               |	Document.CashRegisterShift AS DocumentCashRegisterShift
	               |		LEFT JOIN CashShiftsVATTaxation AS CashShiftsVATTaxation
	               |		ON (CashShiftsVATTaxation.CashRegisterShift = DocumentCashRegisterShift.Ref)
	               |		LEFT JOIN Document.RetailReturnsReport AS RetailReturnsReport
	               |		ON (RetailReturnsReport.CashRegisterShift = DocumentCashRegisterShift.Ref)
	               |			AND (RetailReturnsReport.VATTaxation = CashShiftsVATTaxation.VATTaxation)
				   |WHERE
				   |	CASE
				   |			WHEN CashShiftsVATTaxation.ThereIsReportOnRefunds IS NULL
				   |				THEN TRUE
				   |			ELSE CASE
				   |					WHEN CashShiftsVATTaxation.ThereIsReportOnRefunds
				   |						THEN ISNULL(RetailReturnsReport.Posted, TRUE)
				   |					ELSE TRUE
				   |				END
				   |		END
	               |{WHERE
	               |	(DocumentCashRegisterShift.Organization = &Organization),
	               |	(DocumentCashRegisterShift.CashRegister = &CashRegister),
	               |	(DocumentCashRegisterShift.CashRegister.Warehouse = &Warehouse),
	               |	(DocumentCashRegisterShift.Date >= &BeginOfPeriod),
	               |	(DocumentCashRegisterShift.Date <= &EndOfPeriod)}";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf