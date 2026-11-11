#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);

EndProcedure

// Adds an object creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//   ValueTableRow   - description of the creation command based on.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Catalogs.Complaints) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Catalogs.Complaints.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Catalogs.Complaints);
		CreateBasedOnCommand.FunctionalOptions = "RecordComplaints";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	Return Undefined;
	
EndFunction

// Used in the interaction mechanism. Returns the client and participants of the transaction
//
// Parameters:
//  Ref  - CatalogRef.Complaints - the claim for which contacts are received.
//
// Returns:
//   Array   - an array containing contacts.
//
Function GetContacts(Ref) Export

	Return SalesOpportunitiesServer.GetParticipantsOnTabularPartOfSubjectOfInteraction(
		Ref, Common.ObjectAttributeValue(Ref,"Partner"));

EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters. 
// 
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters - Array of parameters of the functions of the settlement mechanism
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	ThisIsClaimToVendor = False;
	ConductComplaintARAP = False;
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(FillingData, "ThisIsClaimToVendor, ConductComplaintARAP");
		ThisIsClaimToVendor = StructureFillingData.ThisIsClaimToVendor;
		ConductComplaintARAP = StructureFillingData.ConductComplaintARAP;
	ElsIf FillingData <> Undefined Then
		ThisIsClaimToVendor = FillingData.ThisIsClaimToVendor;
		ConductComplaintARAP = FillingData.ConductComplaintARAP;
	EndIf;
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	#Region RequiredParameters2
	
	ParametersStructure.IsCatalog                    = True;
	
	//Determines which register the parameters move, which common forms, enumerations and directories to use.
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	If ThisIsClaimToVendor Then
		ParametersStructure.PaymentType_                  = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	EndIf;
	
	//With certain values of the document details, he may not change the mutual settlements in terms of payments or shipments.
	//An example is the transfer of goods to the commission.

	//If both flags are negative, then the hyperlink "Calculations" is hidden, the amounts of mutual settlements and tabular parts of the mechanism are cleared.
	//If the value is negative, the Offset and Payment stages buttons will be hidden, but it will be possible to change currencies and the exchange rate.
	ParametersStructure.ChangesPaymentPlan               = False;
	ParametersStructure.ModifiesDeliveryShipmentPlan     = False;
	
	// It is not an object of the AR/AP object if no calculations are carried out.
	ParametersStructure.ItCanBeARAPObject = ConductComplaintARAP;
	
	//The date the document was reflected in the system.
	//It is used to get overdue balances for the debt limitation function.
	//Used to get the document's currency rates. 
	//Used to fill in the payment stages and decrypt the default payment.
	ParametersStructure.Date                             = "Object.RegistrationDate"; 
	// The system number of the object
	ParametersStructure.Number                            = "Object.Code"; 
	
	//Currency and amount of the transaction. The path to the object's details is required.
	ParametersStructure.DocumentCurrency                  = "Object.Currency";
	ParametersStructure.DocumentAmount                   = "Object.Sum";
	
	//They are used to generate calculation and analytics objects.
	ParametersStructure.Partner                          = "Object.Partner";
	ParametersStructure.Counterparty                       = "Object.Counterparty";
	
	#EndRegion
	
	#Region OptionalParameters
	
	//It is used to generate analytics for the conduct and object of calculations, to determine the schedule for the execution of the contract.
	ParametersStructure.Contract                          = "Object.Contract";
	//It is used to generate the analysis of the conduct and object of calculations.
	ParametersStructure.LineOfBusiness          = "Object.LineOfBusiness";
	
	//The procedure for calculating the document.
	ParametersStructure.ARAPObjectSettings                  = Enums.ARAPObjectSettings.ByCounterpartyContracts;
		
	//It is used to fill in the default values, fill in the schedule of scheduled payments and the payment date.
	ParametersStructure.Terms                       = "";
	
	//They are used to determine the value of payments in currency and in the form of editing payment rules.
	ParametersStructure.CompanyBankAccount        = "";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.CashAccount                            = "";
	ParametersStructure.PaymentMethod                      = "";
	ParametersStructure.ForeignCurrencyTransaction                    = "";
	//It is used in the form of payment rules and for the selection of settlement objects in the decryption of the payment.
	ParametersStructure.PaymentID             = "";
	ParametersStructure.VATTaxation               = "";
	
	//The storage location of the reference/references to the Calculation Objects directory.
	ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	
	//The details for the object of calculations are used in conducting.
	ParametersStructure.Department                    = "Object.GuiltyBusinessUnit";
	ParametersStructure.Manager                         = "Object.EmployeeResponsible";
	
	//The name of the form element containing the financial accounting group to reflect the current set of parameters for the BU.
	ParametersStructure.FormItems.FinancialAccountingGroup = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	
	#EndRegion
	
	Return ParametersStructure;
	
EndFunction

// Initializes parameters for registering debt adjustments
//
// Parameters:
//  Object		- CatalogObject.Complaints, FormDataStructure	- the Catalog Element to get parameters for.
//
// Returns:
// 	Structure - Structure of parameters with keys:
// 	     * Ref - CatalogRef - Link to the claim.
// 	     * Organization - CatalogRef.Companies - The organization in which the claim is reflected.
// 	     * Counterparty - CatalogRef.Counterparties, CatalogRef.Companies - Counterparty or organization.
//
Function ParametersForRegisteringDebtAdjustments(Object) Export
	
	RegistrationParameters = New Structure();
	RegistrationParameters.Insert("Ref");
	RegistrationParameters.Insert("ARAPObject");
	RegistrationParameters.Insert("Date", '00010101');
	RegistrationParameters.Insert("Organization");
	RegistrationParameters.Insert("Counterparty");
	
	RegistrationParameters.Ref					= Object.Ref;
	RegistrationParameters.ARAPObject			= Object.ARAPObject;
	RegistrationParameters.Date					= Object.RegistrationDate;
	RegistrationParameters.Organization			= Object.Organization;
	RegistrationParameters.Counterparty				= Object.Counterparty;
	
	Return RegistrationParameters;
	
EndFunction

// Returns 
// - the text of the display of debt adjustments entered on the basis of the claim.
// - links data of debt adjustments.
// 
// Parameters:
// 	RegistrationParameters - See ParametersForRegisteringDebtAdjustments
// Returns:
// 	Structure - LongDesc:
//	* ThereIsRightToInteractivelyAddDocumentOnBasisOf - Boolean
// 	* DebtAdjustments - Array 
// 	* Presentation - FormattedString
Function DebtAdjustmentsIntroducedOnBasisOf(RegistrationParameters) Export
	
	Result = New Structure();
	Result.Insert("Presentation", New FormattedString(""));
	Result.Insert("DebtAdjustments",  New Array);
	Result.Insert("ThereIsRightToInteractivelyAddDocumentOnBasisOf",  False);
	
	DebtAdjustments = New Array;
	TextDebtAdjustment = NStr("vi = 'Tạo điều chỉnh công nợ';
								|ru = 'Оформить корректировку задолженности';
								|en = 'Register an AR/AP adjustment'; fa = 'Register an AR/AP adjustment';
								|it = 'Оформить корректировку задолженности';
								|pl = 'Register an AR/AP adjustment';
								|tr = 'Borç tahsisi düzenle'");
	URL = "IntroduceNewDebtAdjustment";
	ThereIsRightToInteractivelyAddDocumentOnBasisOf = False;
	
	
	ThereIsRightToInteractivelyAddDocumentOnBasisOf = AccessRight("InteractiveInsert", Metadata.Documents.ARAPAdjustment);
		
	Filter = New Structure();
	Filter.Insert("Organization", RegistrationParameters.Organization);
	TableDebtAdjustments = Documents.ARAPAdjustment.DebtAdjustmentsBasedOn(RegistrationParameters.Ref, Filter,  Undefined, False);
		
	TableDebtAdjustments.GroupBy("Number,Date,Posted,Ref");
		
	If TableDebtAdjustments.Count() > 0 Then
		If TableDebtAdjustments.Count() > 1 Then
			TextDebtAdjustment = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Điều chỉnh công nợ (%1)';
						|ru = 'Корректировки задолженности (%1)';
						|en = 'AR/AP adjustments (%1)'; fa = 'AR/AP adjustments (%1)';
						|it = 'Корректировки задолженности (%1)';
						|pl = 'AR/AP adjustments (%1)';
						|tr = 'Borç tahsisleri (%1)'"),
				    String(TableDebtAdjustments.Count()));
			URL = "OpenListOfDebtAdjustments";
		Else
			DebtAdjustments = TableDebtAdjustments[0];
			TextDebtAdjustment = Documents.ARAPAdjustment.PresentationOfDebtAdjustment(
					DebtAdjustments.Number, DebtAdjustments.Date, DebtAdjustments.Posted);
			URL = "OpenDebtAdjustment";
		EndIf;
	ElsIf ThereIsRightToInteractivelyAddDocumentOnBasisOf Then
		TextDebtAdjustment = NStr("vi = 'Tạo điều chỉnh công nợ';
									|ru = 'Оформить корректировку задолженности';
									|en = 'Register an AR/AP adjustment'; fa = 'Register an AR/AP adjustment';
									|it = 'Оформить корректировку задолженности';
									|pl = 'Register an AR/AP adjustment';
									|tr = 'Borç tahsisi düzenle'");
		URL = "IntroduceNewDebtAdjustment";
	Else
		TextDebtAdjustment = NStr("vi = 'Chưa tạo điều chỉnh công nợ';
									|ru = 'Корректировка задолженности не оформлена';
									|en = 'AR/AP adjustment is not registered'; fa = 'AR/AP adjustment is not registered';
									|it = 'Корректировка задолженности не оформлена';
									|pl = 'AR/AP adjustment is not registered';
									|tr = 'Borç tahsisi düzenlenmedi'");
	EndIf;
		
	DebtAdjustments = TableDebtAdjustments.UnloadColumn("Ref");
		
	If ValueIsFilled(URL) Then
		TextColor = StyleColors.HyperlinkColor;
	Else
		TextColor = Undefined;
	EndIf;
	
	If RegistrationParameters.Property("DocumentPresentationPostfix") Then
		PresentationPostfix = RegistrationParameters.DocumentPresentationPostfix;
		SubstringsArray = New Array();
		SubstringsArray.Add(TextDebtAdjustment);
		SubstringsArray.Add(PresentationPostfix);
		TextDebtAdjustment = StrConcat(SubstringsArray, " ");
	EndIf;

	Presentation = New FormattedString(TextDebtAdjustment, , TextColor, , URL);
	
	Result.Insert("Presentation", Presentation);
	Result.Insert("DebtAdjustments",  DebtAdjustments);
	Result.Insert("ThereIsRightToInteractivelyAddDocumentOnBasisOf", ThereIsRightToInteractivelyAddDocumentOnBasisOf);
	
	Return Result;

EndFunction

// Returns 
// - the text of the display of debt adjustments registered on the basis of the claim.
// - references debt adjustment data.
// 
// Parameters:
// 	RegistrationParameters - See ParametersForRegisteringDebtAdjustments
// Returns:
// 	Structure - LongDesc:
// * ThereIsRightToInteractivelyAddDocumentOnBasisOf - Boolean -
// * DocumentOnBasisIsRequired - Boolean -
// * DebtAdjustments - Array of DocumentRef
// * Presentation - FormattedString -
Function DebtAdjustmentBasedOn(RegistrationParameters) Export
	
	Result = New Structure();
	Result.Insert("Presentation", New FormattedString(""));
	Result.Insert("DebtAdjustments",  New Array);
	Result.Insert("DocumentOnBasisIsRequired",  False);
	Result.Insert("ThereIsRightToInteractivelyAddDocumentOnBasisOf",  False);
	
	DebtAdjustments = New Array;
	TextDebtAdjustment = NStr("vi = 'Không cần tạo điều chỉnh công nợ';
								|ru = 'Оформление корректировки задолженности не требуется';
								|en = 'AR/AP adjustment registration is not required'; fa = 'AR/AP adjustment registration is not required';
								|it = 'Оформление корректировки задолженности не требуется';
								|pl = 'AR/AP adjustment registration is not required';
								|tr = 'Borç tahsisinin düzenlenmesi gerekmemektedir'");
	URL = "";
	ThereIsRightToInteractivelyAddDocumentOnBasisOf = False;
	
	ThereIsRightToInteractivelyAddDocumentOnBasisOf = AccessRight("InteractiveInsert", Metadata.Documents.ARAPAdjustment);
		
	Filter = New Structure();
	Filter.Insert("Organization", RegistrationParameters.Organization);
	TableDebtAdjustments = Documents.ARAPAdjustment.DebtAdjustmentsBasedOn(RegistrationParameters.Ref, Filter,  Undefined, False);
	TableDebtAdjustments.GroupBy("Number,Date,Posted,Ref");
	
	If TableDebtAdjustments.Count() > 0 Then
		If TableDebtAdjustments.Count() > 1 Then
			TableDebtAdjustments = StringFunctionsClientServer.SubstituteParametersToString(
			                      NStr("vi = 'Điều chỉnh công nợ (%1)';
										|ru = 'Корректировки задолженности (%1)';
										|en = 'AR/AP adjustments (%1)'; fa = 'AR/AP adjustments (%1)';
										|it = 'Корректировки задолженности (%1)';
										|pl = 'AR/AP adjustments (%1)';
										|tr = 'Borç tahsisleri (%1)'"),
			                      String(TableDebtAdjustments.Count()));
			URL = "OpenListOfDebtAdjustments";
		Else
			ARAPAdjustment = TableDebtAdjustments[0];
			TextDebtAdjustment = Documents.ARAPAdjustment.PresentationOfDebtAdjustment(
									ARAPAdjustment.Number, ARAPAdjustment.Date, ARAPAdjustment.Posted);
			URL = "Open_DebtAdjustment";
		EndIf;
	ElsIf ThereIsRightToInteractivelyAddDocumentOnBasisOf Then
		TextDebtAdjustment = NStr("vi = 'Tạo điều chỉnh công nợ';
									|ru = 'Оформить корректировку задолженности';
									|en = 'Register an AR/AP adjustment'; fa = 'Register an AR/AP adjustment';
									|it = 'Оформить корректировку задолженности';
									|pl = 'Register an AR/AP adjustment';
									|tr = 'Borç tahsisi düzenle'");
		URL = "EnterNewDebtAdjustment";
	Else
		TextDebtAdjustment = NStr("vi = 'Chưa tạo điều chỉnh công nợ';
									|ru = 'Корректировка задолженности не оформлена';
									|en = 'AR/AP adjustment is not registered'; fa = 'AR/AP adjustment is not registered';
									|it = 'Корректировка задолженности не оформлена';
									|pl = 'AR/AP adjustment is not registered';
									|tr = 'Borç tahsisi düzenlenmedi'");
	EndIf;
	
	DebtAdjustments = TableDebtAdjustments.UnloadColumn("Ref");
	
	If ValueIsFilled(URL) Then
		TextColor = StyleColors.HyperlinkColor;
	Else
		TextColor = Undefined;
	EndIf;
	
	If RegistrationParameters.Property("DocumentPresentationPostfix") Then
		PresentationPostfix = RegistrationParameters.DocumentPresentationPostfix;
		SubstringsArray = New Array();
		SubstringsArray.Add(TextDebtAdjustment);
		SubstringsArray.Add(PresentationPostfix);
		TextInvoice = StrConcat(SubstringsArray, " ");
	EndIf;

	Presentation = New FormattedString(TextDebtAdjustment, , TextColor, , URL);
	
	Result = New Structure;
	Result.Insert("Presentation", Presentation);
	Result.Insert("DebtAdjustments",  DebtAdjustments);
	Result.Insert("ThereIsRightToInteractivelyAddDocumentOnBasisOf", ThereIsRightToInteractivelyAddDocumentOnBasisOf);
	
	Return Result;

EndFunction

// For use with software interface methods
// Forms a representation of the commands for the formation of only debt adjustment based on the transferred structure for debt adjustment 
// returned by the Document functions.Debt adjustmentsadjustments.The adjustment is due to the basis().
//
// Parameters:
//	Basis - CatalogRef.Complaints - The claim on the basis of which the debt adjustment is introduced
//	DebtAdjustmentBasedOn - See Documents.ARAPAdjustment.DebtAdjustmentsBasedOn
//
// Returns:
//	String, FormattedString - Presentation in the parameter parametersfor the formation of the presentation supplemented 
//                                  by the formatted text of the Presentation of the debt adjustment in the document.
Function ToFormPresentationOfCommandsForFormationOfDebtAdjustmentBasedOn(Basis, DebtAdjustmentBasedOn = Undefined) Export
	
	PresentationsArray = New Array;
	
	If DebtAdjustmentBasedOn <> Undefined Then
		PresentationsArray.Add(DebtAdjustmentBasedOn.Presentation);
	Else
		PresentationsArray.Add("");
	EndIf;
	
	Result = New FormattedString(PresentationsArray);
	
	Return Result;
	
EndFunction

Function ARAPObjectOfClaim(Object) Export
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	ARAPObjects.Ref AS Ref
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|WHERE
	|	ARAPObjects.Object = &Object
	|	AND NOT ARAPObjects.DeletionMark";
	
	Query.SetParameter("Object", Object);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	Else
		Return Catalogs.ARAPObjects.EmptyRef();
	EndIf;
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
	|	ValueAllowed(Partner)";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = ThisList.Partner
	|
	|LEFT JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|	ON ContactPersonsForPartners.Owner = ThisList.Partner
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersContactPersons
	|	ON ExternalUsersContactPersons.AuthorizationObject = ContactPersonsForPartners.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(ExternalUsersPartners.Ref)
	|	OR ValueAllowed(ExternalUsersContactPersons.Ref)";

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

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		StandardProcessing = False;
		If FormType = "ObjectForm" Then
			SelectedForm = "SelfServiceWorkplaceItemForm";
		ElsIf FormType = "ListForm" Then
			SelectedForm = "SelfServiceWorkplaceListForm";
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "Claim";
	PrintCommand.Presentation = NStr("vi = 'Khiếu nại';
									|ru = 'Претензия';
									|en = 'Complaint'; fa = 'شکایت';
									|it = 'Reclamo';
									|pl = 'Complaint';
									|tr = 'Şikayet'");

EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "Claim") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection,
		                                                     "Claim",
		                                                     NStr("vi = 'Khiếu nại';
																	|ru = 'Претензия';
																	|en = 'Complaint'; fa = 'شکایت';
																	|it = 'Reclamo';
																	|pl = 'Complaint';
																	|tr = 'Şikayet'"),
		                                                     GeneratePrintForm(ObjectsArray, PrintObjects));
		
		PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
		
	EndIf;
	
EndProcedure

// Fills in the structure with data about recipients of printed forms.
// Parameters:
// 	PrintObjectDataStructure - See PrintFormGeneration.FillInRecipientStructureDataByObjectType.PrintObjectDataStructure
// 
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export

	PrintObjectDataStructure.PrimaryRecipient = "Partner";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Partner");
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("PartnersAndContactPersons.ContactPerson");

EndProcedure 

Function GeneratePrintForm(Claim, PrintObjects)
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	Query = New Query;
	
	Query.Text =
	"SELECT
	|	Complaints.Ref,
	|	Complaints.Description,
	|	CASE
	|		WHEN Complaints.Status = VALUE(Enum.CustomerComplaintStatuses.Registered1)
	|				OR Complaints.Status = VALUE(Enum.CustomerComplaintStatuses.InProcessing)
	|			THEN PRESENTATION(Complaints.Status)
	|		ELSE &Discussed
	|	END AS PresentationStatus,
	|	Complaints.Status,
	|	Complaints.ComplaintDescription,
	|	Complaints.ProcessingResult,
	|	Complaints.RegistrationDate,
	|	Complaints.EndDate,
	|	Complaints.EmployeeResponsible
	|FROM
	|	Catalog.Complaints AS Complaints
	|WHERE
	|	Complaints.Ref = &Claim";
	
	If TypeOf(Claim) = Type("Array") Then
		Query.SetParameter("Claim", Claim[Claim.Count() - 1]);
	Else
		Query.SetParameter("Claim", Claim);
	EndIf;
	Query.SetParameter("Discussed", NStr("vi = 'Đã xem xét';
										|ru = 'Рассмотрена';
										|en = 'Reviewed'; fa = 'بررسی‌شده';
										|it = 'Presa in esame';
										|pl = 'Reviewed';
										|tr = 'İncelendi'"));
	
	FillOutClaimTabularDocument(SpreadsheetDocument, Query, PrintObjects);
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

Procedure FillOutClaimTabularDocument(SpreadsheetDocument, Query, PrintObjects) Export
	
	PrintData = Query.Execute().Select();
	PrintData.Next();
	
	RowNumberStart = SpreadsheetDocument.TableHeight + 1;
	
	Template = PrintManagement.PrintFormTemplate("Catalog.Complaints.PF_MXL_Claim");

	HeaderArea_ = Template.GetArea("Title");

	HeaderArea_.Parameters.TitleText = StringFunctionsClientServer.SubstituteParametersToString(PrintData.Description + " %1 " + Format(PrintData.RegistrationDate,"DLF=DD"),NStr("vi = 'ngày';
																																													|ru = 'от';
																																													|en = 'dated'; fa = 'مورخ';
																																													|it = 'del';
																																													|pl = 'dated';
																																													|tr = 'tarih'"));
	
	BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, HeaderArea_, PrintData.Ref);
	SpreadsheetDocument.Put(HeaderArea_);
	
	SectionHeader = Template.GetArea("Header");
	FillPropertyValues(SectionHeader.Parameters, PrintData);
	SpreadsheetDocument.Put(SectionHeader);
	
	If PrintData.Status = Enums.CustomerComplaintStatuses.Fulfilled_ 
		Or PrintData.Status = Enums.CustomerComplaintStatuses.NotFulfilled_ Then
	
		AreaOfConsideration = Template.GetArea("Review");
		FillPropertyValues(AreaOfConsideration.Parameters, PrintData);
		SpreadsheetDocument.Put(AreaOfConsideration);
	
	EndIf;
	
	PrintManagement.SetDocumentPrintArea(
			SpreadsheetDocument,
			RowNumberStart,
			PrintObjects,
			PrintData.Ref);
	
EndProcedure

#EndRegion

Function AutoDescription(Object) Export
	
	AutoDescription = NStr("vi = 'Khiếu nại của khách hàng';
							|ru = 'Претензия клиента';
							|en = 'Customer complaint'; fa = 'شکایت مشتری';
							|it = 'Reclamo del cliente';
							|pl = 'Reklamacje klienta';
							|tr = 'Müşteri şikayeti'");
	If Object.ThisIsClaimToVendor Then
		AutoDescription = NStr("vi = 'Khiếu nại nhà cung cấp';
								|ru = 'Претензия поставщику';
								|en = 'Complaint to vendor'; fa = 'Complaint to vendor';
								|it = 'Reclamo al fornitore';
								|pl = 'Roszczenie do dostawcy';
								|tr = 'Tedarikçiye şikayet'");
	EndIf;
	Template = NStr("vi = '%1 ngày %2';
					|ru = '%1 от %2';
					|en = '%1 from %2'; fa = '%1 from %2';
					|it = '%1 del %2';
					|pl = '%1 z dn. %2';
					|tr = '%2 tarihli %1'", Common.DefaultLanguageCode());
	NumberDate = StringFunctionsClientServer.SubstituteParametersToString(Template, Object.Code, Format(Object.RegistrationDate, "DLF=D"));
	
	Return AutoDescription + " " + NumberDate;
		
EndFunction

#EndRegion

#EndIf
