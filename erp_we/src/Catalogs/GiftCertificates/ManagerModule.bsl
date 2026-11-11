#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Gets the object's details that need to be blocked from being changed
//
// Returns:
//  Array of String - The locking details of the object
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	Result.Add("Owner");
	Result.Add("Code");
	Result.Add("Description");
	Result.Add("Barcode");
	Result.Add("MagneticCode");
	
	Return Result;

EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	ParametersArray = New Array();
	
	#Region BasicStructure
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	// Determines which register the parameters move, which common forms, enumerations and directories to use.
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;

	ParametersStructure.ChangesPaymentPlan = True;
	
	ParametersStructure.Number                            = "";
	ParametersStructure.Date                             = "";
	ParametersStructure.Organization                      = "Object.Owner.Organization";
	
	ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	
	// Currency and amount of the transaction. The path to the object's details is required.
	ParametersStructure.DocumentCurrency                  = "Object.Owner.Currency";
	ParametersStructure.DocumentAmount                   = "Object.Owner.Nominal";
	
	ParametersStructure.Counterparty                       = "Object.Counterparty";
	ParametersStructure.Partner                          = "Object.Partner";
	ParametersStructure.Contract                          = "";
	ParametersStructure.ARAPObjectSettings                  = Enums.ARAPObjectSettings.ByARAPDocuments;

	// It is used to fill in the default values, fill in the schedule of scheduled payments and the payment date.
	ParametersStructure.Terms                       = "";
	
	// They are used to determine the value of payments in currency and in the form of editing payment rules.
	ParametersStructure.CompanyBankAccount        = "";
	ParametersStructure.CashAccount                            = "";
	ParametersStructure.PaymentMethod                      = "";
	ParametersStructure.ForeignCurrencyTransaction                    = "";
	ParametersStructure.CounterpartyBankAccount        = "";
	
	// It is used in the form of payment rules and for the selection of settlement objects in the decryption of the payment.
	ParametersStructure.PaymentID             = "Object.PaymentID";
	ParametersStructure.VATTaxation               = "Object.VATTaxation";
	
	// It is used when reflecting settlements with clients in regulated and international accounts.
	ParametersStructure.FinancialAccountingGroup           = "Object.Owner.FinancialAccountingGroup";
	
	ParametersStructure.IsCatalog                    = True;
	
	ParametersArray.Add(ParametersStructure);
	
	#EndRegion
	
	Return ParametersArray;
	
EndFunction

// Determines whether the gift certificate is a certificate of type 2.5
// 
// Parameters:
//  GiftCertificate - CatalogObject.GiftCertificates - Gift certificate
// 
// Returns:
//  Boolean - True if the gift certificate is 2.5
Function GiftCardAccounting25(GiftCertificate) Export
	
	GiftCardAccounting25 = Common.ObjectAttributeValue(GiftCertificate.Owner, "GiftCardAccounting25");
	
	Return GiftCardAccounting25;
	
EndFunction

// Returns the matching of gift certificates to the transferred payment objects.
// 
// Parameters:
//  ARAPObjects - Array of CatalogRef.ARAPObjects - Array of calculation objects.
//
// Returns:
//  Map of KeyAndValue:
//   * Key - CatalogRef.ARAPObjects -
//   * Value - CatalogRef.GiftCertificates -
//
Function GiftCertificatesForSettlementObjects(ARAPObjects) Export
	Result = New Map;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GiftCertificates.Ref AS GiftCertificate,
	|	ARAPObjects.Ref AS ARAPObject
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|		
	|		INNER JOIN Catalog.GiftCertificates AS GiftCertificates
	|		ON GiftCertificates.Ref = ARAPObjects.Object
	|		
	|		LEFT JOIN Catalog.GiftCertificateKinds AS GiftCertificateKinds
	|		ON GiftCertificates.Owner = GiftCertificateKinds.Ref
	|WHERE
	|	GiftCertificateKinds.GiftCardAccounting25 = TRUE
	|	AND ARAPObjects.Ref IN (&ArrayOfCalculationObjects_)";
	Query.SetParameter("ArrayOfCalculationObjects_", ARAPObjects);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result.Insert(Selection.ARAPObject, Selection.GiftCertificate);
	EndDo; 
	
	Return Result;
EndFunction

// Receives a selection of data about gift certificates by document for further processing
//
// Parameters:
//  SelectionByGiftCertificate - CatalogRef.GiftCertificates, Array of CatalogRef.GiftCertificates -
//  Object - DocumentObject -
//
// Returns:
//	QueryResultSelection -
Function SelectionOfDataOnGiftCertificatesForProcessing(SelectionByGiftCertificate, Object) Export
	
	Query = New Query(
	"SELECT
	|	GiftCertificates.Ref AS GiftCertificate,	
	|	GiftCertificates.Owner.Nominal AS Nominal,
	|	GiftCertificates.Owner.Currency  AS NominalCurrency,
	|	ISNULL(ActivatingGiftCertificates.Active, FALSE) AS ActivationStatus,
	|	ISNULL(ActivatingGiftCertificates.Organization, CASE
	|			WHEN GiftCertificates.Owner.GiftCardAccounting25
	|				THEN GiftCertificates.Owner.Organization
	|			ELSE VALUE(Catalog.Companies.EmptyRef)
	|		END) AS Organization,
	|	GiftCertificates.Owner AS GiftCertificateKind,
	|	GiftCertificates.Owner.GiftCardAccounting25 AS GiftCardAccounting25,
	|	GiftCertificates.Owner.Nominal
	|	* CASE
	|		WHEN &Currency <> GiftCertificates.Owner.Currency
	|			THEN CASE
	|					WHEN ISNULL(CurrencyExchangeRatesCertificates.CourseDenominator, 0) > 0
	|						AND ISNULL(CurrencyExchangeRatesCertificates.CourseNumerator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|					THEN 
	|						(CurrencyExchangeRatesCertificates.CourseNumerator * Currency_Rates.CourseDenominator)
	|						/ (Currency_Rates.CourseNumerator * CurrencyExchangeRatesCertificates.CourseDenominator)
	|					ELSE 0
	|				END
	|		ELSE 1
	|	END AS Sum,
	|	ISNULL(ActivatingGiftCertificates.ValidityStartDate, DATETIME(1, 1, 1)) AS ValidityStartDate,
	|	ISNULL(ActivatingGiftCertificates.ValidityEndDate, DATETIME(1, 1, 1)) AS ValidityEndDate,
	|	ISNULL(ActivatingGiftCertificates.Recorder, UNDEFINED) DocumentSalesOfGoodsAndServices
	|FROM
	|	Catalog.GiftCertificates AS GiftCertificates
	|	
	|LEFT JOIN
	|	InformationRegister.RelativeExchangeRates.SliceLast(&BorderDateEndOfDay, BaseCurrency = &BaseCurrency) AS CurrencyExchangeRatesCertificates
	|ON 
	|	GiftCertificates.Owner.Currency = CurrencyExchangeRatesCertificates.Currency
	|	AND GiftCertificates.Ref IN (&Ref)
	|	
	|LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&BorderDateEndOfDay, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS Currency_Rates
	|	ON TRUE
	|	
	|LEFT JOIN InformationRegister.ActivatingGiftCertificates AS ActivatingGiftCertificates
	|	ON ActivatingGiftCertificates.GiftCertificate = GiftCertificates.Ref	
	|
	|WHERE
	|	GiftCertificates.Ref IN (&Ref)
	|");
	
	Query.SetParameter("Ref", SelectionByGiftCertificate);
	Query.SetParameter("Currency", Object.Currency);
	CurrentSessionDate = CurrentSessionDate();
	If ValueIsFilled(Object.Date) Then
		CurrentSessionDate = Object.Date;
	EndIf;
	Query.SetParameter("BorderDateEndOfDay",   New Boundary(EndOfDay(CurrentSessionDate),BoundaryType.Including));
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization));
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	Return Selection;
	
EndFunction

// Fills in the Attributes of the gift certificate with pre-calculated data;
// It is assumed that the verification of the need to record this data is done before calling the method.
// 
// Parameters:
//  GiftCertificate - CatalogRef.GiftCertificates - Gift certificate.
//  DataToFill - Map of KeyAndValue:
//   * Key - String - the name of the Catalog Attributes gift certificates
//   * Value - String - Attribute name of the sales document
//
Procedure FillInAttributesOfGiftCertificate(GiftCertificate, DataToFill) Export
	
	If Not ValueIsFilled(GiftCertificate) Or DataToFill.Count() = 0 Then
		Return;
	EndIf;
	
	CatalogObject = GiftCertificate.GetObject();
	For Each KeyValue In DataToFill Do
		If Not CatalogObject[KeyValue.Key] = KeyValue.Value Then
			CatalogObject[KeyValue.Key] = KeyValue.Value;
		EndIf;
	EndDo;
	
	If CatalogObject.Modified() Then
		SetPrivilegedMode(True);
		CatalogObject.Write();
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export

	TeamBusinessProcessesTask = BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	If NewOnlineARAPAccounting Then		
		TeamBusinessProcessesTask.Order = 99;
		
		AllowedStatusesForRefund = New Array;
		AllowedStatusesForRefund.Add(Enums.GiftCertificateStatuses.Activated);
		
		// Return of gift certificates
		NewCommand = Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
		If NewCommand <> Undefined Then
			NewCommand.Handler = "GiftCertificatesClient.SelectCounterpartyToEnterPaymentDocumentBasedOnGiftCertificate";
			NewCommand.FormName = "Document.PaymentRequest.Form.DocumentForm";
			NewCommand.VisibilityInForms =
				"ListForm,ItemForm";
			NewCommand.MultipleChoice = False;
			
			AttachableCommands.AddCommandVisibilityCondition(NewCommand,
																"GiftCardAccounting25",
																True,
																DataCompositionComparisonType.Equal);
			AttachableCommands.AddCommandVisibilityCondition(NewCommand,
																"Status",
																AllowedStatusesForRefund,
																DataCompositionComparisonType.InList);
			
		EndIf;
		NewCommand = Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
		If NewCommand <> Undefined Then
			NewCommand.Handler = "GiftCertificatesClient.SelectCounterpartyToEnterPaymentDocumentBasedOnGiftCertificate";
			NewCommand.FormName = "Document.CashVoucher.Form.DocumentForm";
			NewCommand.VisibilityInForms =
				"ListForm,ItemForm";
			NewCommand.MultipleChoice = False;
			
			AttachableCommands.AddCommandVisibilityCondition(NewCommand,
																"GiftCardAccounting25",
																True,
																DataCompositionComparisonType.Equal);
			AttachableCommands.AddCommandVisibilityCondition(NewCommand,
																"Status",
																AllowedStatusesForRefund,
																DataCompositionComparisonType.InList);
			
		EndIf;
		
		NewCommand = Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
		If NewCommand <> Undefined Then
			NewCommand.Handler = "GiftCertificatesClient.SelectCounterpartyToEnterPaymentDocumentBasedOnGiftCertificate";
			NewCommand.FormName = "Document.BankAccountIssue.Form.DocumentForm";
			NewCommand.VisibilityInForms =
				"ListForm,ItemForm";
			NewCommand.MultipleChoice = False;
			
			AttachableCommands.AddCommandVisibilityCondition(NewCommand,
																"GiftCardAccounting25",
																True,
																DataCompositionComparisonType.Equal);
			AttachableCommands.AddCommandVisibilityCondition(NewCommand,
																"Status",
																AllowedStatusesForRefund,
																DataCompositionComparisonType.InList);
			
		EndIf;
						
		// Gift certificate sales
		NewCommand = Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
		If NewCommand <> Undefined Then
			NewCommand.Handler = "GiftCertificatesClient.SelectCounterpartyToEnterPaymentDocumentBasedOnGiftCertificate";
			NewCommand.FormName = "Document.CashAccountReceiptNote.Form.DocumentForm";
			NewCommand.VisibilityInForms =
				"ListForm,ItemForm";
			NewCommand.MultipleChoice = False;

			AttachableCommands.AddCommandVisibilityCondition(NewCommand,
																"GiftCardAccounting25",
																True,
																DataCompositionComparisonType.Equal);
			AttachableCommands.AddCommandVisibilityCondition(NewCommand,
																"Status",
																Enums.GiftCertificateStatuses.NotActivated,
																DataCompositionComparisonType.Equal);
			
		EndIf;
		
		NewCommand = Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);
		If NewCommand <> Undefined Then
			NewCommand.Handler = "GiftCertificatesClient.SelectCounterpartyToEnterPaymentDocumentBasedOnGiftCertificate";
			NewCommand.FormName = "Document.BankAccountReceiptNote.Form.DocumentForm";
			NewCommand.VisibilityInForms =
				"ListForm,ItemForm";
			NewCommand.MultipleChoice = False;
			AttachableCommands.AddCommandVisibilityCondition(NewCommand,
																"GiftCardAccounting25",
																True,
																DataCompositionComparisonType.Equal);
			AttachableCommands.AddCommandVisibilityCondition(NewCommand,
																"Status",
																Enums.GiftCertificateStatuses.NotActivated,
																DataCompositionComparisonType.Equal);
			
		EndIf;
		
		
		// Sale/Refund of gift certificates depending on the business transaction.
		NewCommand = Documents.PaymentCardTransaction.AddGenerateCommand(GenerationCommands);
		If NewCommand <> Undefined Then
			NewCommand.Handler = "GiftCertificatesClient.SelectCounterpartyToEnterPaymentDocumentBasedOnGiftCertificate";
			NewCommand.FormName = "Document.PaymentCardTransaction.Form.DocumentForm";
			NewCommand.VisibilityInForms =
				"ListForm,ItemForm";
			NewCommand.MultipleChoice = False;
			AttachableCommands.AddCommandVisibilityCondition(NewCommand,
																"GiftCardAccounting25",
																True,
																DataCompositionComparisonType.Equal);
			PermittedPSStatusesForAcquiring = New Array;
			PermittedPSStatusesForAcquiring.Add(Enums.GiftCertificateStatuses.NotActivated);
			PermittedPSStatusesForAcquiring.Add(Enums.GiftCertificateStatuses.Activated);

			AttachableCommands.AddCommandVisibilityCondition(NewCommand,
																"Status",
																PermittedPSStatusesForAcquiring,
																DataCompositionComparisonType.InList);
			
		EndIf;

	EndIf;
		
EndProcedure

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	If GetFunctionalOption("UseGiftCards")
		And (AccessRight("Use", Metadata.DataProcessors.PrintGiftCards)
			Or Users.IsFullUser()) Then
		// Gift certificate
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintGiftCards";
		PrintCommand.Id = "GiftCertificate";
		PrintCommand.Presentation = NStr("vi = 'Phiếu quà tặng';
										|ru = 'Подарочный сертификат';
										|en = 'Gift card'; fa = 'کارت هدیه';
										|it = 'Buono regalo';
										|pl = 'Certyfikat podarunkowy';
										|tr = 'Hediye kartı'");
		PrintCommand.CheckPostingBeforePrint = False;
	EndIf;

EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array    - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - value - the object reference;
//                                            view - name of the area where the object was output (output parameter);
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	Return;
	
EndProcedure

// The function receives data for generating a printed Gift certificate form.
//
// Parameters:
//  PrintParameters - Structure - print settings.
//  ObjectsArray - Array - Array of gift certificates.
//
// Returns:
//  Structure - structure with properties:
//   * QueryResult - QueryResult - query result.
//   * DocumentTitle - String - Document title.
//
Function GetDataForPrintedGiftCertificateForm(PrintParameters, ObjectsArray) Export
	
	SetPrivilegedMode(True);

	Query = New Query(
	"SELECT
	|	GiftCertificates.Ref        AS Ref,
	|	GiftCertificates.Code           AS SerialNumber,
	|	GiftCertificates.Barcode      AS Barcode,
	|	GiftCertificates.MagneticCode  AS MagneticCode,
	|	GiftCertificates.Owner.Nominal  AS Nominal,
	|	GiftCertificates.Owner.Currency   AS Currency
	|FROM
	|	Catalog.GiftCertificates AS GiftCertificates
	|WHERE
	|	GiftCertificates.Ref IN (&DocumentsArray)
	|");
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	QueryResult = Query.Execute();
	
	DataStructureForPrinting    = New Structure("QueryResult, DocumentTitle",
	                                               QueryResult, NStr("vi = 'Phiếu quà tặng';
																	|ru = 'Подарочный сертификат';
																	|en = 'Gift card'; fa = 'کارت هدیه';
																	|it = 'Buono regalo';
																	|pl = 'Certyfikat podarunkowy';
																	|tr = 'Hediye kartı'"));
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return DataStructureForPrinting;
	
EndFunction

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

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm";
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region EventHandlers

#EndRegion

#Region Private

#EndRegion

#Region InfobaseUpdate

#EndRegion

#EndIf
