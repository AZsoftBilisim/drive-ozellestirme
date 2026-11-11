#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Executes the methods of the patch assistant processing object module.
//
// Parameters:
//  Parameters - Structure - structure with fields:
//		* StructureOfProcessingObject - Structure - The structure from which the processing object will be restored. The structure fields must match the
//			metadata fields of the organization's data processing helpers.
//		* MethodNames - Array - An array of strings with the names of methods to execute.
//		* MethodParameters_ - Structure - A structure where keys match method names and values contain arrays of parameters for these methods.
//  ResultAddress - String - The address to temporary storage to place the object structure after all methods are executed.
//  DataProcessorObject	- DataProcessorObject.WizardOfCorrectingCompanyStockBalance - processing object, if it does not need to be restored from
//		the structure.
//
Procedure ExecuteObjectMethods(Parameters, ResultAddress = Undefined, DataProcessorObject = Undefined) Export
	
	If DataProcessorObject = Undefined Then
		DataProcessorObject = DataProcessorObject(Parameters.StructureOfProcessingObject);
	EndIf;
	
	BriefErrorDescription = "";
	
	Methods = StrSplit(Parameters.MethodNames, ",");
	For Each Method In Methods Do
		Try
			Method = TrimAll(Method);
			If Method = "UpdateDataOnNegativeBalancesAndBalances" Then
				DataProcessorObject.UpdateDataOnNegativeBalancesAndBalances();
			ElsIf Method = "FillInMonthOfCorrection" Then
				DataProcessorObject.FillInMonthOfCorrection();
			ElsIf Method = "CreateNewReserves" Then
				DataProcessorObject.CreateNewReserves();
			ElsIf Method = "CreateNewReservesForNewSettings" Then
				DataProcessorObject.CreateNewReservesForNewSettings();
			ElsIf Method = "GenerateCorrectionsToExpandedBalance" Then
				DataProcessorObject.GenerateCorrectionsToExpandedBalance();
			ElsIf Method = "TypesOfOffsetOfBalancesOfExpandedBalance" Then
				DataProcessorObject.TypesOfOffsetOfBalancesOfExpandedBalance();
			ElsIf Method = "RefillInventoryKinds" Then
				DataProcessorObject.RefillInventoryKinds();
			ElsIf Method = "FillInNewTransferSettings" Then
				DataProcessorObject.FillInNewTransferSettings();
			ElsIf Method = "FillOutOrdersForRegistrationOfRegistrationForms" Then
				DataProcessorObject.FillOutOrdersForRegistrationOfRegistrationForms();
			ElsIf Method = "ReFormationOfReservesIsNotRequired" Then
				DataProcessorObject.ReFormationOfReservesIsNotRequired();
			ElsIf Method = "CorrectionOfUnfoldedBalanceIsRequired" Then
				DataProcessorObject.CorrectionOfUnfoldedBalanceIsRequired();
			ElsIf Method = "GenerateReplacementTaxInvoices" Then
				DataProcessorObject.GenerateReplacementTaxInvoices();
			ElsIf Method = "ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement" Then
				DataProcessorObject.ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement(
					Parameters.MethodParameters_.ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement[0],
					Parameters.MethodParameters_.ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement[1]);
			ElsIf Method = "Initialize" Then
				DataProcessorObject.Initialize();
			Else
				ExceptionText = NStr("vi = 'Không hỗ trợ làm việc với phương thức %Method%';
									|ru = 'Работа с методом %Method% не поддерживается';
									|en = 'Work with the %Method% method is not supported'; fa = 'Work with the %Method% method is not supported';
									|it = 'Il lavoro con il metodo %Method% non è supportato';
									|pl = 'Praca z metodą %Method% nie jest obsługiwana';
									|tr = '%Method% metodu ile çalışma desteklenmiyor'");
				ExceptionText = StrReplace(ExceptionText, "%Method%", Method);
				Raise ExceptionText;
			EndIf;
		Except
			ErrorInfo = ErrorInfo();
			BriefErrorDescription = BriefErrorDescription(ErrorInfo);
			Break;
		EndTry;	
	EndDo;
	
	If ValueIsFilled(ResultAddress) Then
		PutToTempStorage(DataProcessorObject.StructureOfData(), ResultAddress);
	EndIf;
	
	If ValueIsFilled(BriefErrorDescription) Then
		Raise BriefErrorDescription;
	EndIf;
	
EndProcedure

// Request detailed balances at the end of the correction month.
// 
// Parameters:
//  MonthOfCorrection - Date
// 
// Returns:
//  Query - Request detailed balances at the end of the month corrections
//
Function RequestDetailedMonthEndBalances(MonthOfCorrection) Export
	
	TempTablesManager = New TempTablesManager;
	GenerateTTControlledInventoryTypes(TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
		InventoriesServer.StopRegisteringRecordsOfCompanyGoodsInTransit("&CorrectionPeriod_") + 
		Common.QueryBatchSeparator() +
		
		"SELECT
		|	CompanyGoodsBalance.Organization 				AS Organization,
		|	CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanyGoodsBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanyGoodsBalance.CCDNumber 					AS CCDNumber,
		|	CompanyGoodsBalance.CountBalance 			AS CountBalance
		|INTO BalancesAtEndOfPeriod
		|FROM
		|	AccumulationRegister.CompanyGoods.Balance(
		|		&CorrectionBoundary,
		|		InventoryOwnerAttribute IN (
		|			SELECT
		|				TTControlledInventoryTypes.Ref
		|			FROM
		|				TTControlledInventoryTypes AS TTControlledInventoryTypes)) AS CompanyGoodsBalance
		|
		|UNION ALL
		|
		|SELECT
		|	CompanyGoodsOnWay.Organization 					AS Organization,
		|	CompanyGoodsOnWay.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	CompanyGoodsOnWay.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	CompanyGoodsOnWay.CCDNumber 					AS CCDNumber,
		|	-CompanyGoodsOnWay.NumberIsReversed			AS CountBalance
		|FROM
		|	CompanyGoodsOnWay AS CompanyGoodsOnWay
		|WHERE
		|	CompanyGoodsOnWay.Period <= &CorrectionPeriod_
		|	AND CompanyGoodsOnWay.InventoryOwnerAttribute IN (
		|		SELECT
		|			TTControlledInventoryTypes.Ref
		|		FROM
		|			TTControlledInventoryTypes AS TTControlledInventoryTypes)
		|
		|UNION ALL
		|
		|SELECT
		|	CompanySafeStockBalance.Organization 				AS Organization,
		|	CompanySafeStockBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanySafeStockBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanySafeStockBalance.CCDNumber 					AS CCDNumber,
		|	CompanySafeStockBalance.CountBalance 			AS CountBalance
		|FROM
		|	AccumulationRegister.CompanySafeStock.Balance(
		|		&CorrectionBoundary,
		|		InventoryOwnerAttribute IN (
		|			SELECT
		|				TTControlledInventoryTypes.Ref
		|			FROM
		|				TTControlledInventoryTypes AS TTControlledInventoryTypes)) AS CompanySafeStockBalance
		|
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	CCDNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CompanyGoodsOnWay
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BalancesAtEndOfPeriod.Organization 					AS Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	BalancesAtEndOfPeriod.CCDNumber 						AS CCDNumber,
		|	SUM(BalancesAtEndOfPeriod.CountBalance) 		AS CountBalance
		|INTO DetailedBalancesAtEndOfMonth
		|FROM
		|	BalancesAtEndOfPeriod AS BalancesAtEndOfPeriod
		|
		|GROUP BY
		|	BalancesAtEndOfPeriod.Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute,
		|	BalancesAtEndOfPeriod.CCDNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP BalancesAtEndOfPeriod";                    

	Query.SetParameter("CorrectionBoundary", New Boundary(EndOfMonth(MonthOfCorrection), BoundaryType.Including));
	Query.SetParameter("CorrectionPeriod_",  EndOfMonth(MonthOfCorrection));

	Return Query;

EndFunction

// To form controlled types of stocks.
// 
// Parameters:
//  TempTablesManager - TempTablesManager - temporary table Manager
//
Procedure GenerateTTControlledInventoryTypes(TempTablesManager) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	InventoryKinds.Ref AS Ref
	|INTO TTControlledInventoryTypes
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.InventoryType IN (&ControlledInventoryTypes)";
	Query.Parameters.Insert("ControlledInventoryTypes", Enums.InventoryTypes.ControlledInventoryTypes());
	Query.Execute();
	
EndProcedure

#EndRegion

#Region Private

Function DataProcessorObject(StructureOfProcessingObject)
	
	DataProcessorObject = DataProcessors.WizardOfCorrectingCompanyStockBalance.Create();
	For Each StructureField In StructureOfProcessingObject Do
		If TypeOf(StructureField.Value) = Type("ValueTable") Then
			DataProcessorObject[StructureField.Key].Load(StructureField.Value);
		Else
			DataProcessorObject[StructureField.Key] = StructureField.Value;
		EndIf;
	EndDo;
	
	Return DataProcessorObject;
	
EndFunction

#EndRegion

#EndIf