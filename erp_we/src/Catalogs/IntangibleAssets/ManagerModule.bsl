#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns information about an intangible asset.
//
// Parameters:
//  IntangibleAsset - CatalogRef.IntangibleAssets	 - An intangible asset for which you need to get information.
//  Period			 - Date - On what date you need to get information.
// 
// Returns:
//  Structure - Contains information about an intangible asset.
//
Function InitialInformation(IntangibleAsset, Period = '000101010000') Export
	
	InitialInformation = IntangibleAssetsLocalization.InitialInformation(IntangibleAsset, Period);
	
	If InitialInformation = Undefined Then
		
		InitialInformation = New Structure;
		InitialInformation.Insert("Organization", Undefined);
		InitialInformation.Insert("Department", Undefined);
		InitialInformation.Insert("DateOfRecognitionManagementAccounting", '000101010000');
		InitialInformation.Insert("DateOfRecognitionAccounting", '000101010000');
		InitialInformation.Insert("DateOfRecognitionInTaxAccounting", '000101010000');
		InitialInformation.Insert("DocumentOfRecognitionManagementAccounting", Undefined);
		InitialInformation.Insert("DocumentOfRecognitionAccounting", Undefined);
		InitialInformation.Insert("RecognitionDocumentTA", Undefined);
		InitialInformation.Insert("StateOfTheUU", Enums.IntangibleAssetsStates.NotPostedInFinancialAccounting);
		InitialInformation.Insert("BUState", Enums.IntangibleAssetsStates.NotPostedInFinancialAccounting);
		InitialInformation.Insert("StateTa", Enums.IntangibleAssetsStates.NotPostedInFinancialAccounting);
		InitialInformation.Insert("ApplicationOfTargetFinancing", False);
		
		If Not ValueIsFilled(IntangibleAsset)
			Or Not AccessRight("Read", Metadata.InformationRegisters.InitialIntangibleAssetsInformation)
			Or Not AccessRight("Read", Metadata.InformationRegisters.IntangibleAssetsAccountingProcedureManagementAccounting) Then
			
			Return InitialInformation;
		EndIf; 
		
		QueryText = 
		"SELECT ALLOWED
		|	InitialInformation.Organization,
		|	InitialInformation.DateOfRecognitionManagementAccounting AS DateOfRecognitionManagementAccounting,
		|	InitialInformation.DateOfRecognitionManagementAccounting AS DateOfRecognitionAccounting,
		|	InitialInformation.DocumentOfRecognitionManagementAccounting AS DocumentOfRecognitionManagementAccounting,
		|	InitialInformation.DocumentOfRecognitionManagementAccounting AS DocumentOfRecognitionAccounting,
		|	ISNULL(AccountingProcedureMA.State, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) AS StateOfTheUU,
		|	ISNULL(AccountingProcedureMA.State, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) AS BUState
		|FROM
		|	InformationRegister.InitialIntangibleAssetsInformation.SliceLast(&Period, IntangibleAsset = &Ref) AS InitialInformation
		|		LEFT JOIN InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast(&Period, IntangibleAsset = &Ref) AS AccountingProcedureMA
		|		ON InitialInformation.IntangibleAsset = AccountingProcedureMA.IntangibleAsset
		|			AND InitialInformation.Organization = AccountingProcedureMA.Organization";
		
		Query = New Query(QueryText);
		Query.SetParameter("Ref", IntangibleAsset);
		Query.SetParameter("Period", Period);
		
		Result = Query.Execute();
		
		If Result.IsEmpty() Then
			Return InitialInformation;
		EndIf;
		
		Selection = Result.Select();
		Selection.Next();
		
		FillPropertyValues(InitialInformation, Selection);
	
	EndIf; 
	
	Return InitialInformation;

EndFunction

// Generates information about accounting for an intangible asset
//
// Parameters:
//  IntangibleAsset - CatalogRef.IntangibleAssets - An intangible asset for which you need to get information.
//  Date - Date -
//  Recorder - DocumentRef -
// 
// Returns:
//  Structure, Map - Contains information about accounting.
//
Function InformationAboutAccounting(IntangibleAsset, Date = '00010101', Recorder = Undefined) Export

	If Not ValueIsFilled(IntangibleAsset) Then
		Return Undefined;
	EndIf;

	If Not AccessRight("Read", Metadata.InformationRegisters.IntangibleAssetsRegistrationPlace)
		Or Not AccessRight("Read", Metadata.InformationRegisters.InitialIntangibleAssetsInformation)
		Or Not AccessRight("Read", Metadata.InformationRegisters.IntangibleAssetsAccountingProcedure)
		Or Not AccessRight("Read", Metadata.InformationRegisters.IntangibleAssetsAccountingProcedureManagementAccounting)
		Or Not AccessRight("Read", Metadata.InformationRegisters.IABookkeepingProcedureBookkeepingAndTaxAccounting)
		Or Not AccessRight("Read", Metadata.InformationRegisters.IADepreciationParametersBookkeepingAndTaxAccounting)
		Or Not AccessRight("Read", Metadata.InformationRegisters.IntangibleAssetAmortizationParametersManagementAccounting) Then
		Return Undefined;
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED
	|	IntangibleAssetsRegistrationPlace.IntangibleAsset AS IntangibleAsset,
	|
	|	ISNULL(InitialInformation.DateOfRecognitionAccounting, DATETIME(1, 1, 1)) AS CommissioningDateAC,
	|	ISNULL(InitialInformation.DateOfRecognitionInTaxAccounting, DATETIME(1, 1, 1)) AS CommissioningDateTA,
	|	ISNULL(InitialInformation.DateOfRecognitionManagementAccounting, DATETIME(1, 1, 1)) AS CommissioningDateMA,
	|
	|	ISNULL(InitialInformation.DocumentOfRecognitionAccounting, UNDEFINED) AS CommissioningDocumentAC,
	|	ISNULL(InitialInformation.RecognitionDocumentTA, UNDEFINED) AS CommissioningDocumentTA,
	|	ISNULL(InitialInformation.DocumentOfRecognitionManagementAccounting, UNDEFINED) AS CommissioningDocumentMA,
	|
	|	ISNULL(InitialInformation.DocumentWriteOffs, UNDEFINED) AS DeregistrationDocumentACC,
	|	ISNULL(InitialInformation.DocumentWriteOffs, UNDEFINED) AS DeregistrationDocumentTA,
	|	ISNULL(InitialInformation.DocumentWriteOffs, UNDEFINED) AS DeregistrationDocumentMA,
	|
	|	ISNULL(InitialInformation.DocumentWriteOffs.Date, DATETIME(1, 1, 1)) AS DateOfDeRegistrationOfBU,
	|	ISNULL(InitialInformation.DocumentWriteOffs.Date, DATETIME(1, 1, 1)) AS DateOfDeRegistrationWELL,
	|	ISNULL(InitialInformation.DocumentWriteOffs.Date, DATETIME(1, 1, 1)) AS DateMaWasDeRegistered,
	|
	|	ISNULL(InitialInformation.InitialCostLocalAccounting, 0) AS InitialCostLocalAccounting,
	|	ISNULL(InitialInformation.InitialCostTA, 0) AS InitialCostTA,
	|
	|	ISNULL(IntangibleAssetsAccountingProcedure.FinancialAccountingGroup, UNDEFINED) AS FinancialAccountingGroup,
	|	ISNULL(IntangibleAssetsAccountingProcedure.FinancialAccountingGroup.Presentation, """") AS FinancialAccountingGroupPresentation,
	|
	|	ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) AS BUState,
	|	ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.StateTa, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) AS StateTa,
	|	ISNULL(IntangibleAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) AS StateOfTheUU,
	|
	|	ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeMonths, 0) AS UsefulLifeManagementAccounting,
	|	ISNULL(IADepreciationParametersBookkeepingAndTaxAccounting.UsefulLifeMonthsAC, 0) AS UsefulLifeAccounting,
	|	ISNULL(IADepreciationParametersBookkeepingAndTaxAccounting.UsefulLifeMonthsTA, 0) AS UsefulLifeTaxAccounting,
	|
	|	ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.ResidualValueMan, 0) AS ResidualValueMan,
	|	ISNULL(IADepreciationParametersBookkeepingAndTaxAccounting.ResidualValueMan, 0) AS ResidualValueLocal,
	|
	|	IntangibleAssetsRegistrationPlace.Period AS PeriodOfInformationAboutPlaceOfRegistration,
	|	IntangibleAssetsRegistrationPlace.Organization AS Organization,
	|	ISNULL(IntangibleAssetsRegistrationPlace.Organization.Presentation, """") AS OrganizationPresentation,
	|	IntangibleAssetsRegistrationPlace.Department AS Department,
	|	IntangibleAssetsRegistrationPlace.IntangibleAsset.KindOfAccountingObject AS KindOfAccountingObject,
	|	ISNULL(IntangibleAssetsRegistrationPlace.Department.Presentation, """") AS DepartmentPresentation
	|
	|FROM
	|	InformationRegister.IntangibleAssetsRegistrationPlace.SliceLast(
	|			&Date, 
	|			Recorder <> &Recorder
	|				AND IntangibleAsset IN (&IntangibleAsset)) AS IntangibleAssetsRegistrationPlace
	|
	|		LEFT JOIN InformationRegister.InitialIntangibleAssetsInformation.SliceLast(
	|				&Date, 
	|				Recorder <> &Recorder
	|					AND IntangibleAsset IN (&IntangibleAsset)) AS InitialInformation
	|		ON (InitialInformation.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset)
	|			AND (InitialInformation.Organization = IntangibleAssetsRegistrationPlace.Organization)
	|
	|		LEFT JOIN InformationRegister.IntangibleAssetsAccountingProcedure.SliceLast(
	|				&Date, 
	|				Recorder <> &Recorder
	|					AND IntangibleAsset IN (&IntangibleAsset)) AS IntangibleAssetsAccountingProcedure
	|		ON (IntangibleAssetsAccountingProcedure.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset)
	|			AND (IntangibleAssetsAccountingProcedure.Organization = IntangibleAssetsRegistrationPlace.Organization)
	|
	|		LEFT JOIN InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast(
	|				&Date, 
	|				Recorder <> &Recorder
	|					AND IntangibleAsset IN (&IntangibleAsset)) AS IntangibleAssetsAccountingProcedureManagementAccounting
	|		ON (IntangibleAssetsAccountingProcedureManagementAccounting.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset)
	|			AND (IntangibleAssetsAccountingProcedureManagementAccounting.Organization = IntangibleAssetsRegistrationPlace.Organization)
	|
	|		LEFT JOIN InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.SliceLast(
	|				&Date, 
	|				Recorder <> &Recorder
	|					AND IntangibleAsset IN (&IntangibleAsset)) AS IABookkeepingProcedureBookkeepingAndTaxAccounting
	|		ON (IABookkeepingProcedureBookkeepingAndTaxAccounting.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset)
	|			AND (IABookkeepingProcedureBookkeepingAndTaxAccounting.Organization = IntangibleAssetsRegistrationPlace.Organization)
	|
	|		LEFT JOIN InformationRegister.IADepreciationParametersBookkeepingAndTaxAccounting.SliceLast(
	|				&Date, 
	|				Recorder <> &Recorder
	|					AND IntangibleAsset IN (&IntangibleAsset)) AS IADepreciationParametersBookkeepingAndTaxAccounting
	|		ON (IADepreciationParametersBookkeepingAndTaxAccounting.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset)
	|			AND (IADepreciationParametersBookkeepingAndTaxAccounting.Organization = IntangibleAssetsRegistrationPlace.Organization)
	|
	|		LEFT JOIN InformationRegister.IntangibleAssetAmortizationParametersManagementAccounting.SliceLast(
	|				&Date, 
	|				Recorder <> &Recorder
	|					AND IntangibleAsset IN (&IntangibleAsset)) AS IntangibleAssetAmortizationParametersManagementAccounting
	|		ON (IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset)
	|			AND (IntangibleAssetAmortizationParametersManagementAccounting.Organization = IntangibleAssetsRegistrationPlace.Organization)
	|";

	Query = New Query(QueryText);
	Query.SetParameter("IntangibleAsset", ?(TypeOf(IntangibleAsset) = Type("Array"), IntangibleAsset, CommonClientServer.ValueInArray(IntangibleAsset)));
	Query.SetParameter("Date", Date);
	Query.SetParameter("Recorder", Recorder);

	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	AccountingInformationTemplate = New Structure();
	For Each QueryColumn In Result.Columns Do
		AccountingInformationTemplate.Insert(QueryColumn.Name);
	EndDo; 
	AccountingInformationTemplate = New FixedStructure(AccountingInformationTemplate);
	
	Selection = Result.Select();

	If TypeOf(IntangibleAsset) = Type("Array") Then
		
		InformationAboutAccounting = New Map();
		While Selection.Next() Do
			
			IAAccountingInformation = New Structure(AccountingInformationTemplate);
			FillPropertyValues(IAAccountingInformation, Selection);
			InformationAboutAccounting.Insert(Selection.IntangibleAsset, IAAccountingInformation);
			
		EndDo;
		
	Else
		
		InformationAboutAccounting = New Structure(AccountingInformationTemplate);
		Selection.Next();
		FillPropertyValues(InformationAboutAccounting, Selection);
		
	EndIf;
		
	Return InformationAboutAccounting;

EndFunction

#Region AttachableCommands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Command = Documents.IntangibleAssetsInitialRecognition2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.ChangeIntangibleAssetFinancialDetails2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.IATransfer2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.IARevaluation2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
		AttachableCommands.AddCommandVisibilityCondition(Command, "KindOfAccountingObject", Enums.IntangibleAssetsAccountingItemKinds.IntangibleAsset);
	EndIf;
	
	Command = Documents.PreparingForIntangibleAssetSale2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.DisposeIntangibleAssets2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.IntangibleAssetsCostAndAmortizationAdjustment.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
		Command.MultipleChoice = True;
	EndIf;
	
	Command = Documents.IntangibleAssetImprovement.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
		Command.WriteMode = "";
	EndIf;
	
	IntangibleAssetsLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Command = Reports.SpreadsheetOfIntangibleAssetsAndRDExpenses.AddReportCommand(ReportsCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
	EndIf;

	Command = Reports.StatementCalculationOfIntangibleAssetsAmortization.AddIAReportCommand(ReportsCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
	EndIf;
	
	Command = Reports.CapitalizationExpenseStructure.AddIAReportCommand(ReportsCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListFormWithInformation";
	EndIf;
	
	IntangibleAssetsLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	IntangibleAssetsLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

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
	
	If FormType = "ChoiceForm" And NonCurrentAssetsServerCall.SelectionOfIntangibleAssets2_4IsAvailable(Parameters) Then
		
		// Concept 2.4 has its own form of choice
		SelectedForm = "ChoiceForm2_4";
		StandardProcessing = False;
		Return;

	EndIf;
	
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ChoiceData = NonCurrentAssetsServerCall.IntangibleAssetSelectionData(Parameters, StandardProcessing);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Function ThereAreRightsToReadInformation() Export

	If Not NonCurrentAssets.VNAManagementIsUsed_2_4()
		Or Not AccessRight("Read", Metadata.InformationRegisters.IntangibleAssetsRegistrationPlace)
		Or Not AccessRight("Read", Metadata.InformationRegisters.InitialIntangibleAssetsInformation)
		Or Not AccessRight("Read", Metadata.InformationRegisters.IntangibleAssetsAccountingProcedureManagementAccounting)
		Or Not AccessRight("Read", Metadata.AccumulationRegisters.IACost)
		Or Not AccessRight("Read", Metadata.AccumulationRegisters.IntangibleAssetsAmortizationCharge)
		Or Not IntangibleAssetsLocalization.ThereAreRightsToReadInformation() Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function PresentationOfAccountingInformation(InformationAboutAccounting, CostAndDepreciation, IncludeBlankFields = True) Export

	ChoiceOfReflectionInAccountsIsAvailable = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	PresentationOfInformation = New Structure;

	InformationReplacementCost = New Array;
	InformationAccumulatedDepreciation = New Array;
	InformationResidualValue = New Array;
	
	InformationImpairment = New Array;
	
	Period = '000101010000';

	NonCurrentAssetsInternal.PresentationOfInformationOnDateOfAcceptanceForAccounting(InformationAboutAccounting, PresentationOfInformation);
	NonCurrentAssetsInternal.PresentationOfInformationAboutPeriodOfUse(InformationAboutAccounting, PresentationOfInformation);
	NonCurrentAssetsInternal.PresentationOfInformationAboutDateOfWriteOff(InformationAboutAccounting, PresentationOfInformation);
	NonCurrentAssetsInternal.PresentationOfInformationOnLiquidationCosts(InformationAboutAccounting, PresentationOfInformation);
	
	#Region GeneralInformation
	
	If InformationAboutAccounting <> Undefined Then
		
		NonCurrentAssetsInternal.PresentationOfInformationByLink(
			"HFCInformation", 
			NStr("vi = 'Nhóm kế toán tài chính:';
				|ru = 'Группа финансового учета:';
				|en = 'Financial accounting group:'; fa = 'گروه حسابداری مالی:';
				|it = 'Gruppo di contabilità finanziaria:';
				|pl = 'Grupa ewidencji finansowej:';
				|tr = 'Finansal muhasebe grubu'"), 
			InformationAboutAccounting.FinancialAccountingGroup, 
			InformationAboutAccounting.FinancialAccountingGroupPresentation, 
			PresentationOfInformation);
			
	Else
		PresentationOfInformation.Insert("HFCInformation", Undefined);
	EndIf;
	
	#EndRegion
	
	#Region FixedAssetsLocation
	
	If InformationAboutAccounting <> Undefined Then
		
		Period = InformationAboutAccounting.PeriodOfInformationAboutPlaceOfRegistration; 
		
		NonCurrentAssetsInternal.PresentationOfInformationByLink(
			"InformationRegistrationPlaceCompany", 
			NStr("vi = 'Doanh nghiệp:';
				|ru = 'Организация:';
				|en = 'Company:'; fa = 'شرکت:';
				|it = 'Организация:';
				|pl = 'Firma:';
				|tr = 'İş yeri:'"), 
			InformationAboutAccounting.Organization, 
			InformationAboutAccounting.OrganizationPresentation, 
			PresentationOfInformation);
			
		NonCurrentAssetsInternal.PresentationOfInformationByLink(
			"InformationRegistrationPlaceDepartment", 
			NStr("vi = 'Bộ phận:';
				|ru = 'Подразделение:';
				|en = 'Business unit:'; fa = 'واحد تجاری:';
				|it = 'Подразделение:';
				|pl = 'Dział:';
				|tr = 'Departman:'"), 
			InformationAboutAccounting.Department, 
			InformationAboutAccounting.DepartmentPresentation, 
			PresentationOfInformation);
			
	Else
		PresentationOfInformation.Insert("InformationRegistrationPlaceCompany", Undefined);
		PresentationOfInformation.Insert("InformationRegistrationPlaceDepartment", Undefined);
	EndIf; 
	
	#EndRegion
	
	#Region Amounts
	
	If Not ChoiceOfReflectionInAccountsIsAvailable 
		And InformationAboutAccounting <> Undefined Then
		
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(InformationAboutAccounting.Organization);
		CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
		
		If ComplCurrency = CurrencyOfMan Then
	
			If InformationAboutAccounting.KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
				
				SumPresentation_ = NonCurrentAssetsInternal.SumPresentation_(
					CostAndDepreciation.Cost, NStr("vi = 'Nguyên giá:';
													|ru = 'Первоначальная стоимость:';
													|en = 'Initial cost:'; fa = 'Initial cost:';
													|it = 'Costo iniziale:';
													|pl = 'Wartość początkowa:';
													|tr = 'Başlangıç değeri:'"), CurrencyOfMan);
				InformationReplacementCost.Add(SumPresentation_);
				
				SumPresentation_ = NonCurrentAssetsInternal.SumPresentation_(
					CostAndDepreciation.Depreciation, NStr("vi = 'Giá trị quy đổi:';
															|ru = 'Погашенная стоимость:';
															|en = 'Repaid cost:'; fa = 'Repaid cost:';
															|it = 'Valore estinto:';
															|pl = 'Wartość spłacona:';
															|tr = 'İade edilen maliyet:'"), CurrencyOfMan);
				InformationAccumulatedDepreciation.Add(SumPresentation_);
			
			Else
				
				SumPresentation_ = NonCurrentAssetsInternal.SumPresentation_(
					CostAndDepreciation.Cost, NStr("vi = 'Chi phí thay thế:';
													|ru = 'Восстановительная стоимость:';
													|en = 'Replacement cost:'; fa = 'Replacement cost:';
													|it = 'Costi recuperabili:';
													|pl = 'Koszt odtworzenia:';
													|tr = 'Yenileme değeri:'"), CurrencyOfMan);
				InformationReplacementCost.Add(SumPresentation_);
				
				SumPresentation_ = NonCurrentAssetsInternal.SumPresentation_(
					CostAndDepreciation.Depreciation, NStr("vi = 'Khấu hao lũy kế:';
															|ru = 'Накопленная амортизация:';
															|en = 'Accumulated amortization:'; fa = 'Accumulated amortization:';
															|it = 'Ammortamenti accumulati:';
															|pl = 'Skumulowana amortyzacja:';
															|tr = 'Birikmiş amortisman:'"), CurrencyOfMan);
				InformationAccumulatedDepreciation.Add(SumPresentation_);
				
				SumPresentation_ = NonCurrentAssetsInternal.SumPresentation_(
					CostAndDepreciation.Cost - CostAndDepreciation.Depreciation, NStr("vi = 'Giá trị còn lại:';
																						|ru = 'Остаточная стоимость:';
																						|en = 'Net book value:'; fa = 'Net book value:';
																						|it = 'Valore residuo:';
																						|pl = 'Wartość rezydualna:';
																						|tr = 'Net defter değeri:'"), CurrencyOfMan);
				InformationResidualValue.Add(SumPresentation_);
				
			EndIf;
			
			SumPresentation_ = NonCurrentAssetsInternal.SumPresentation_(
					CostAndDepreciation.ImpairmenMan, NStr("vi = 'Giảm giá trị:';
															|ru = 'Обесценение:';
															|en = 'Impairment:'; fa = 'Impairment:';
															|it = 'Svalutazione:';
															|pl = 'Utrata wartości:';
															|tr = 'Değer kaybı:'"), CurrencyOfMan);
			InformationImpairment.Add(SumPresentation_);
		
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	PresentationOfInformation.Insert("Period", Period);
	PresentationOfInformation.Insert("InformationReplacementCost", InformationReplacementCost);
	PresentationOfInformation.Insert("InformationAccumulatedDepreciation", InformationAccumulatedDepreciation);
	PresentationOfInformation.Insert("InformationResidualValue", InformationResidualValue);
	PresentationOfInformation.Insert("InformationImpairment", InformationImpairment);
	
	Return PresentationOfInformation;

EndFunction

#EndRegion

#Region Private

#Region Print

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	OutputParameters.PrintingBySetsIsAvailable = True;
	
	IntangibleAssetsLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure
	
#EndRegion

#Region Other

// Returns the selection parameters based on the passed parameters and the rights settings.
// 
// Parameters:
//  Parameters - Structure - Parameters
//  RightsSettings - Structure - Rights settings
// 
// Returns:
//  Structure - The selection parameters
//
Function GetChoiceParameters(Parameters, RightsSettings) Export
	
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("Filter", New Structure);
	
	// Various parameters
		
	NonCurrentAssetsClientServer.CopyStructureProperty(Parameters, ChoiceParameters, "DateOfLastEdit");
	NonCurrentAssetsClientServer.CopyStructureProperty(Parameters, ChoiceParameters, "CurrentRegistrar");
	NonCurrentAssetsClientServer.CopyStructureProperty(Parameters, ChoiceParameters, "RecordInLocalAccounting");
	NonCurrentAssetsClientServer.CopyStructureProperty(Parameters, ChoiceParameters, "RecordInManAccounting");
	NonCurrentAssetsClientServer.CopyStructureProperty(Parameters, ChoiceParameters, "PostInAccounting");
	NonCurrentAssetsClientServer.CopyStructureProperty(Parameters, ChoiceParameters, "RecordInTA");
	NonCurrentAssetsClientServer.CopyStructureProperty(Parameters, ChoiceParameters, "AttributesThatShouldMatch");
	
	If Parameters.Property("Context") Then
		ChoiceParameters.Insert("Context", New Structure(Parameters.Context));
	Else
		ChoiceParameters.Insert("Context", New Structure("MA,ACC"));
	EndIf;

	// Filters

	ListFilter = CommonClientServer.StructureProperty(Parameters, "Filter", New Structure); // Structure
	
	ItemsToDelete1 = New Array;
	For Each FilterDetails In ListFilter Do
		
		FilterName = Upper(FilterDetails.Key);
		
		If Not ValueIsFilled(ListFilter[FilterName])
			
			
			Or Not RightsSettings.ThereIsRightToRead_PlaceOfIARegistration
				And (FilterName = Upper("Organization")
					Or FilterName = Upper("Department"))
			
			Or Not RightsSettings.ThereIsRightToRead_InitialInformationIA
				And (FilterName = Upper("DateOfRegistrationOfTheRegl")
					Or FilterName = Upper("DateOfRegistrationOfTheUpr"))
			
			Or Not RightsSettings.ThereIsRightToRead_AccountingProcedureForIA
				And (FilterName = Upper("FinancialAccountingGroup")
					Or FilterName = Upper("LineOfBusiness"))
		
			Or Not RightsSettings.ThereIsRightReading_DepreciationParametersNMAUU
				And FilterName = Upper("UsefulLifeManagementAccounting")
					
			Or Not RightsSettings.ThereIsRightReading_NMABUDepreciationParameters
				And (FilterName = Upper("UsefulLifeAccounting")
					Or FilterName = Upper("UsefulLifeTaxAccounting"))
		
			Or Not RightsSettings.ThereIsRightToRead_AccountingProcedureNMAUU
				And FilterName = Upper("StateOfTheUU")
		
			Or Not RightsSettings.ThereIsRightToRead_NMABUAccountingProcedure
				And (FilterName = Upper("BUState")
					Or FilterName = Upper("VATTaxation")) Then
		
			// Deleting selections with an empty value and selections based on inaccessible information
			ItemsToDelete1.Add(FilterName);
			
			Continue;
			
		EndIf; 
		
		If FilterName = Upper("State")
			Or FilterName = Upper("DepreciationGroup") Then
			
			FilterValue = NonCurrentAssetsInternal.ValueToArray(FilterDetails.Value);
	
			ChoiceParameters.Filter.Insert(FilterName, FilterValue);
			
		Else
				
			NonCurrentAssetsClientServer.CopyStructureProperty(ListFilter, ChoiceParameters.Filter, FilterName);

		EndIf; 
		
	EndDo;
		
	For Each FilterName In ItemsToDelete1 Do
		Parameters.Filter.Delete(FilterName);
	EndDo;
	
	Return ChoiceParameters;
	
EndFunction

// Generates a description of the request for selecting Catalog items.
// 
// Parameters:
//  ChoiceParameters - See GetChoiceParameters
//  RightsSettings - Structure - Rights settings
//  ConsiderInformation - Boolean - True if you need to take into account the selection based on information from the registers (Organization, Division, etc.)
//	SetFilters - Boolean - True if you want to generate a selection text for all selections of the selection parameters
// 
// Returns:
//  Structure - Request parameters to select:
// 		* TextSelections - String - 
// 		* RequiredTables - Structure - 
// 		* QueryFields - Structure - 
// 		* QueryOptions - Structure -
//
Function DescriptionOfItemSelectionRequest(ChoiceParameters, RightsSettings, ConsiderInformation, SetFilters = False) Export

	QueryDetails = New Structure;
	QueryDetails.Insert("TextSelections", "");
	QueryDetails.Insert("RequiredTables", New Structure);
	QueryDetails.Insert("QueryOptions", New Structure);
	
	QueryDetails.Insert("QueryFields", New Structure);
	QueryDetails.QueryFields.Insert("Organization", "VALUE(Catalog.Companies.EmptyRef)");
	QueryDetails.QueryFields.Insert("Department", "VALUE(Catalog.BusinessStructure.EmptyRef)");
	QueryDetails.QueryFields.Insert("LineOfBusiness", "VALUE(Catalog.LinesOfBusiness.EmptyRef)");
	QueryDetails.QueryFields.Insert("BUState", "VALUE(Enum.IntangibleAssetsStates.EmptyRef)");
	QueryDetails.QueryFields.Insert("StateOfTheUU", "VALUE(Enum.IntangibleAssetsStates.EmptyRef)");
	QueryDetails.QueryFields.Insert("FinancialAccountingGroup", "VALUE(Catalog.NonCurrentAssetsAccountingGroups.EmptyRef)");
	QueryDetails.QueryFields.Insert("UsefulLifeManagementAccounting", "0");
	QueryDetails.QueryFields.Insert("UsefulLifeAccounting", "0");
	QueryDetails.QueryFields.Insert("UsefulLifeTaxAccounting", "0");
	QueryDetails.QueryFields.Insert("VATTaxation", "VALUE(Enum.VATTaxationTypes.EmptyRef)");
	QueryDetails.QueryFields.Insert("DateOfRegistrationOfTheRegl", "DATETIME(1,1,1)");
	QueryDetails.QueryFields.Insert("DateOfRegistrationOfTheUpr", "DATETIME(1,1,1)");

	AvailableContexts = ChoiceParameters.Context; // Structure
	ListFilter = Common.CopyRecursive(ChoiceParameters.Filter); // Structure

	#Region QueryFields
	
	If RightsSettings.ThereIsRightToRead_PlaceOfIARegistration
		And (AvailableContexts.Property("ACC") Or AvailableContexts.Property("MA"))
		And (ConsiderInformation Or SetFilters) Then
		
		QueryDetails.QueryFields.Organization = "ISNULL(IntangibleAssetsRegistrationPlace.Organization, VALUE(Catalog.Companies.EmptyRef))";
		QueryDetails.QueryFields.Department = "ISNULL(IntangibleAssetsRegistrationPlace.Department, VALUE(Catalog.BusinessStructure.EmptyRef))";
		
		If ConsiderInformation Then
			QueryDetails.RequiredTables.Insert("IntangibleAssetsRegistrationPlace");
		EndIf;

	EndIf;
	
	If RightsSettings.ThereIsRightToRead_AccountingProcedureForIA
		And (AvailableContexts.Property("ACC") Or AvailableContexts.Property("MA"))
		And (ConsiderInformation Or SetFilters) Then
		
		QueryDetails.QueryFields.FinancialAccountingGroup = 
			"ISNULL(IntangibleAssetsAccountingProcedure.FinancialAccountingGroup, VALUE(Catalog.NonCurrentAssetsAccountingGroups.EmptyRef))"; // @query-part-1
			
		QueryDetails.QueryFields.LineOfBusiness = 
			"ISNULL(IntangibleAssetsAccountingProcedure.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))"; // @query-part-1
		
		If ConsiderInformation Then
			QueryDetails.RequiredTables.Insert("IntangibleAssetsAccountingProcedure");
		EndIf;

	EndIf;
	
	If RightsSettings.ThereIsRightToRead_InitialInformationIA
		And RightsSettings.ThereIsRightToRead_PlaceOfIARegistration
		And (AvailableContexts.Property("ACC") Or AvailableContexts.Property("MA"))
		And (ConsiderInformation Or SetFilters) Then
		
		QueryDetails.QueryFields.DateOfRegistrationOfTheRegl = 
			"CASE 
			|	WHEN ISNULL(InitialIntangibleAssetsInformation.DateOfRecognitionAccounting, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1)
			|			AND (ISNULL(InitialIntangibleAssetsInformation.DateOfRecognitionAccounting, DATETIME(1, 1, 1)) <= ISNULL(InitialIntangibleAssetsInformation.DateOfRecognitionInTaxAccounting, DATETIME(1, 1, 1))
			|				OR ISNULL(InitialIntangibleAssetsInformation.DateOfRecognitionInTaxAccounting, DATETIME(1, 1, 1)) = DATETIME(1, 1, 1))
			|		THEN ISNULL(InitialIntangibleAssetsInformation.DateOfRecognitionAccounting, DATETIME(1, 1, 1))
			|	ELSE ISNULL(InitialIntangibleAssetsInformation.DateOfRecognitionInTaxAccounting, DATETIME(1, 1, 1))
			|END"; // @query-part-1
			
		QueryDetails.QueryFields.DateOfRegistrationOfTheUpr =
			"ISNULL(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting, DATETIME(1, 1, 1))"; // @query-part-1
		
		If ConsiderInformation Then
			QueryDetails.RequiredTables.Insert("InitialIntangibleAssetsInformation");
		EndIf;
		
	EndIf;

	If RightsSettings.ThereIsRightReading_DepreciationParametersNMAUU
		And (ChoiceParameters.Property("AttributesThatShouldMatch")
				And StrFind(ChoiceParameters.AttributesThatShouldMatch, "UsefulLifeManagementAccounting") <> 0 
			Or ChoiceParameters.Filter.Property("UsefulLifeManagementAccounting"))
		And (ConsiderInformation Or SetFilters) Then
		
		QueryDetails.QueryFields.UsefulLifeManagementAccounting = "ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeMonths, 0)"; // @query-part-1
		
		If ConsiderInformation Then
			QueryDetails.RequiredTables.Insert("IntangibleAssetAmortizationParametersManagementAccounting");
		EndIf;
		
	EndIf;
	
	If RightsSettings.ThereIsRightReading_NMABUDepreciationParameters
		And (ChoiceParameters.Property("AttributesThatShouldMatch")
				And StrFind(ChoiceParameters.AttributesThatShouldMatch, "UsefulLifeAccounting") <> 0 
			Or ListFilter.Property("UsefulLifeAccounting"))
		And (ConsiderInformation Or SetFilters) Then
		
		QueryDetails.QueryFields.UsefulLifeAccounting = "ISNULL(IADepreciationParametersBookkeepingAndTaxAccounting.UsefulLifeMonthsAC, 0)"; // @query-part-1
		QueryDetails.QueryFields.UsefulLifeTaxAccounting = "ISNULL(IADepreciationParametersBookkeepingAndTaxAccounting.UsefulLifeMonthsTA, 0)"; // @query-part-1
		
		If ConsiderInformation Then
			QueryDetails.RequiredTables.Insert("IADepreciationParametersBookkeepingAndTaxAccounting");
		EndIf;
		
	EndIf;
	
	If AvailableContexts.Property("ACC") 
		And RightsSettings.ThereIsRightToRead_NMABUAccountingProcedure
		And (ConsiderInformation Or SetFilters) Then
		
		QueryDetails.QueryFields.BUState =
			"CASE 
			|	WHEN CatalogDataOverridable.IsFolder 
			|		THEN VALUE(Enum.IntangibleAssetsStates.EmptyRef)
			|	WHEN IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState <> VALUE(Enum.IntangibleAssetsStates.EmptyRef)
			|		THEN IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState
			|	ELSE ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.StateTa, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting))
			|END"; // @query-part-1
	
		QueryDetails.QueryFields.VATTaxation =		
			"ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.VATTaxation, UNDEFINED)"; // @query-part-1
			
		If ConsiderInformation Then
			QueryDetails.RequiredTables.Insert("IABookkeepingProcedureBookkeepingAndTaxAccounting");
		EndIf;
		
	Else
		
		QueryDetails.QueryFields.BUState = 
			"CASE 
			|	WHEN NOT CatalogDataOverridable.IsFolder 
			|		THEN VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)
			|		ELSE VALUE(Enum.IntangibleAssetsStates.EmptyRef)
			|END"; // @query-part-1
			
	EndIf; 
	
	If AvailableContexts.Property("MA")
		And RightsSettings.ThereIsRightToRead_AccountingProcedureNMAUU
		And (ConsiderInformation Or SetFilters) Then
		
		QueryDetails.QueryFields.StateOfTheUU =
			"CASE 
			|	WHEN NOT CatalogDataOverridable.IsFolder 
			|		THEN ISNULL(IntangibleAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting))
			|		ELSE VALUE(Enum.IntangibleAssetsStates.EmptyRef)
			|END"; // @query-part-1
		
		If ConsiderInformation Then
			QueryDetails.RequiredTables.Insert("IntangibleAssetsAccountingProcedureManagementAccounting");
		EndIf;
		
	Else
		
		QueryDetails.QueryFields.StateOfTheUU =
			"CASE 
			|	WHEN NOT CatalogDataOverridable.IsFolder 
			|		THEN VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)
			|		ELSE VALUE(Enum.IntangibleAssetsStates.EmptyRef)
			|END"; // @query-part-1
		
	EndIf;

	#EndRegion
	
	#Region FiltersCustom
		
	If RightsSettings.ThereIsRightToRead_AccountingProcedureNMAUU 
		And RightsSettings.ThereIsRightToRead_NMABUAccountingProcedure
		And (ConsiderInformation Or SetFilters And ListFilter.Property("State")) Then
		
		ChoiceOfAccountingIsAvailable = 
			ChoiceParameters.Property("RecordInLocalAccounting") 
			Or ChoiceParameters.Property("RecordInManAccounting"); // In the document there is a choice in which accounting it is reflected
	
		If ChoiceOfAccountingIsAvailable Then

			RecordInManAccounting = False;
			PostInAccounting = False;
			RecordInTA = False;

			If ChoiceParameters.Property("RecordInManAccounting") Then
				RecordInManAccounting = ChoiceParameters.RecordInManAccounting;
			EndIf;
			
			If ChoiceParameters.Property("PostInAccounting") Then
				PostInAccounting = ChoiceParameters.PostInAccounting;
			ElsIf ChoiceParameters.Property("RecordInLocalAccounting") Then
				PostInAccounting = ChoiceParameters.RecordInLocalAccounting;
			EndIf;
			
			
			If RecordInManAccounting And PostInAccounting And RecordInTA And ChoiceParameters.Property("RecordInTA") Then
				
				ConditionText =
					"(ISNULL(IntangibleAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN(&State)
					|			AND ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN(&State)
					|			AND ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.StateTa, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN(&State)
					|		OR &DoNotUseStateSelection)"; // @query-part-1
					
				QueryDetails.RequiredTables.Insert("IABookkeepingProcedureBookkeepingAndTaxAccounting");
				QueryDetails.RequiredTables.Insert("IntangibleAssetsAccountingProcedureManagementAccounting");
				QueryDetails.RequiredTables.Insert("IntangibleAssetsRegistrationPlace");
				
			ElsIf RecordInManAccounting And PostInAccounting And RecordInTA And Not ChoiceParameters.Property("RecordInTA") Then
				
				ConditionText =
					"(ISNULL(IntangibleAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN(&State)
					|			AND (ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN(&State)
					|				OR ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.StateTa, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN(&State))
					|		OR &DoNotUseStateSelection)"; // @query-part-1
					
				QueryDetails.RequiredTables.Insert("IABookkeepingProcedureBookkeepingAndTaxAccounting");
				QueryDetails.RequiredTables.Insert("IntangibleAssetsAccountingProcedureManagementAccounting");
				QueryDetails.RequiredTables.Insert("IntangibleAssetsRegistrationPlace");
				
			ElsIf RecordInManAccounting And Not PostInAccounting And Not RecordInTA Then
				
				ConditionText =
					"(ISNULL(IntangibleAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN(&State)
					|		OR &DoNotUseStateSelection)"; // @query-part-1
					
				QueryDetails.RequiredTables.Insert("IntangibleAssetsAccountingProcedureManagementAccounting");
				QueryDetails.RequiredTables.Insert("IntangibleAssetsRegistrationPlace");
				
			ElsIf PostInAccounting And Not RecordInTA And Not RecordInManAccounting Then
				
				ConditionText =
					"(ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN(&State)
					|		OR &DoNotUseStateSelection)"; // @query-part-1
					
				QueryDetails.RequiredTables.Insert("IABookkeepingProcedureBookkeepingAndTaxAccounting");
				QueryDetails.RequiredTables.Insert("IntangibleAssetsRegistrationPlace");
				
			ElsIf RecordInTA And ChoiceParameters.Property("RecordInTA") And Not PostInAccounting And Not RecordInManAccounting Then
				
				ConditionText =
					"(ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.StateTa, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN(&State)
					|		OR &DoNotUseStateSelection)"; // @query-part-1
					
				QueryDetails.RequiredTables.Insert("IABookkeepingProcedureBookkeepingAndTaxAccounting");
				QueryDetails.RequiredTables.Insert("IntangibleAssetsRegistrationPlace");
				
			ElsIf PostInAccounting And RecordInTA And ChoiceParameters.Property("RecordInTA") And Not RecordInManAccounting Then
				
				ConditionText =
					"(ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN(&State)
					|			AND ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.StateTa, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN(&State)
					|		OR &DoNotUseStateSelection)"; // @query-part-1
					
				QueryDetails.RequiredTables.Insert("IABookkeepingProcedureBookkeepingAndTaxAccounting");
				QueryDetails.RequiredTables.Insert("IntangibleAssetsRegistrationPlace");
				
			ElsIf PostInAccounting And RecordInTA And Not ChoiceParameters.Property("RecordInTA") And Not RecordInManAccounting Then
				
				ConditionText =
					"(ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN(&State)
					|		OR ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.StateTa, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN(&State)
					|		OR &DoNotUseStateSelection)"; // @query-part-1
					
				QueryDetails.RequiredTables.Insert("IABookkeepingProcedureBookkeepingAndTaxAccounting");
				QueryDetails.RequiredTables.Insert("IntangibleAssetsRegistrationPlace");
				
			Else
				
				ConditionText = 
					"(ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN(&State)
					|		OR ISNULL(IntangibleAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN(&State)
					|		OR &DoNotUseStateSelection)"; // @query-part-1
					
				
				QueryDetails.RequiredTables.Insert("IABookkeepingProcedureBookkeepingAndTaxAccounting");
				QueryDetails.RequiredTables.Insert("IntangibleAssetsAccountingProcedureManagementAccounting");
				QueryDetails.RequiredTables.Insert("IntangibleAssetsRegistrationPlace");
				
			EndIf;
							
		Else
			
			ConditionText = 
				"(ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN(&State)
				|		OR ISNULL(IntangibleAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN(&State)
				|		OR &DoNotUseStateSelection)"; // @query-part-1
			
			
			QueryDetails.RequiredTables.Insert("IABookkeepingProcedureBookkeepingAndTaxAccounting");
			QueryDetails.RequiredTables.Insert("IntangibleAssetsAccountingProcedureManagementAccounting");
			QueryDetails.RequiredTables.Insert("IntangibleAssetsRegistrationPlace");

		EndIf; 
		
		NonCurrentAssetsInternal.AddSelectionText(QueryDetails.TextSelections, ConditionText);
		
	EndIf; 
		
	#EndRegion
	
	#Region SelectionsByAttributes
	
	If SetFilters Then
		
		For Each KeyAndValue In ListFilter Do
			
			FilterName = Upper(KeyAndValue.Key);
			
			If ThisIsSelectionBasedOnInformation(FilterName)
				And QueryDetails.QueryFields.Property(FilterName)
				And FilterName <> Upper("State") Then
				
				PathToField = QueryDetails.QueryFields[KeyAndValue.Key];
				
				If FilterName = Upper("Organization")
					Or FilterName = Upper("Department") Then
					
					QueryDetails.RequiredTables.Insert("IntangibleAssetsRegistrationPlace");
				
				ElsIf FilterName = Upper("LineOfBusiness")
					Or FilterName = Upper("FinancialAccountingGroup") Then	
				
					QueryDetails.RequiredTables.Insert("IntangibleAssetsAccountingProcedure");
					
				ElsIf FilterName = Upper("BUState")
					Or FilterName = Upper("VATTaxation") Then
					
					QueryDetails.RequiredTables.Insert("IABookkeepingProcedureBookkeepingAndTaxAccounting");
					
				ElsIf FilterName = Upper("StateOfTheUU") Then
					
					QueryDetails.RequiredTables.Insert("IntangibleAssetsAccountingProcedureManagementAccounting");
					
				ElsIf FilterName = Upper("UsefulLifeAccounting")
					Or FilterName = Upper("UsefulLifeTaxAccounting") Then
					
					QueryDetails.RequiredTables.Insert("IADepreciationParametersBookkeepingAndTaxAccounting");
					
				ElsIf FilterName = Upper("UsefulLifeManagementAccounting") Then
					
					QueryDetails.RequiredTables.Insert("IntangibleAssetAmortizationParametersManagementAccounting");
					
				ElsIf FilterName = Upper("DateOfRegistrationOfTheRegl")
					Or FilterName = Upper("DateOfRegistrationOfTheUpr") Then
					
					QueryDetails.RequiredTables.Insert("InitialIntangibleAssetsInformation");
					
				EndIf;
				
			ElsIf FilterName = Upper("IntangibleAssetGroup")
				Or FilterName = Upper("IntangibleAssetsKind")
				Or FilterName = Upper("KindOfAccountingObject")
				Or FilterName = Upper("DepreciationGroup") Then
				
				PathToField = "CatalogDataOverridable" + "." + KeyAndValue.Key;
			
			Else
				
				Continue;
				
			EndIf;
			
			ThisIsArray = 
				TypeOf(KeyAndValue.Value) = Type("FixedArray") 
				Or TypeOf(KeyAndValue.Value) = Type("Array");
						
			ConditionText = PathToField + ?(ThisIsArray, " IN " + "(&" + KeyAndValue.Key + ")", " = &" + KeyAndValue.Key); // @query-part-1
			NonCurrentAssetsInternal.AddSelectionText(QueryDetails.TextSelections, ConditionText);
			
			If ThisIsArray Then
				FilterValue = NonCurrentAssetsInternal.ValueToArray(KeyAndValue.Value);
			Else
				FilterValue = KeyAndValue.Value;
			EndIf;
			
			QueryDetails.QueryOptions.Insert(KeyAndValue.Key, FilterValue);
			
		EndDo; 
		
	EndIf;
	
	#EndRegion
	
	Return QueryDetails;
	
EndFunction

Function HistoryOfChangingProps(IntangibleAsset, AttributeName) Export

	QueryText = 
	"SELECT
	|	IntangibleAssetsDocuments.Date AS Date,
	|	IntangibleAssetsDocuments.Ref AS Document
	|FROM
	|	InformationRegister.IntangibleAssetsDocuments AS IntangibleAssetsDocuments
	|		INNER JOIN Document.ChangeIntangibleAssetFinancialDetails2_4 AS ChangeIntangibleAssetFinancialDetails
	|		ON (ChangeIntangibleAssetFinancialDetails.Ref = IntangibleAssetsDocuments.Ref)
	|WHERE
	|	IntangibleAssetsDocuments.IntangibleAsset = &IntangibleAsset
	|	AND IntangibleAssetsDocuments.RefType = &RefType
	|	AND IntangibleAssetsDocuments.RecNo = 0
	|	AND IntangibleAssetsDocuments.Posted
	|	AND NOT IntangibleAssetsDocuments.AdditionalRecord
	|	AND ChangeIntangibleAssetFinancialDetails.LineOfBusinessFlag
	|	AND &AttributeName = ""LineOfBusiness""
	|
	|ORDER BY
	|	IntangibleAssetsDocuments.Date";
	
	Query = New Query(QueryText);
	Query.SetParameter("IntangibleAsset", IntangibleAsset);
	Query.SetParameter("AttributeName", AttributeName);
	Query.SetParameter("RefType", Common.MetadataObjectID(Type("DocumentRef.ChangeIntangibleAssetFinancialDetails2_4")));
	
	SetPrivilegedMode(True);
	ChangeHistory = Query.Execute().Unload();
	SetPrivilegedMode(False);

	Return ChangeHistory;
	
EndFunction

// Defines the selection attribute based on information.
// 
// Parameters:
//  FilterName - String - Selection name
// 
// Returns:
//  Boolean - True if it is a selection based on information
Function ThisIsSelectionBasedOnInformation(FilterName) Export

	Result =
		Upper(FilterName) = Upper("Organization")
		Or Upper(FilterName) = Upper("Department")
		Or Upper(FilterName) = Upper("LineOfBusiness")
		Or Upper(FilterName) = Upper("State")
		Or Upper(FilterName) = Upper("StateOfTheUU")
		Or Upper(FilterName) = Upper("BUState")
		Or Upper(FilterName) = Upper("FinancialAccountingGroup");
			
	Return Result;
	 	
EndFunction

#EndRegion

#EndRegion

#EndIf