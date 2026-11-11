#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Retrieves the reversal transactions of the document (s).
//
// Parameters:
//  Recorders - DocumentRef - documents (an array of documents) for which you need to get reverse transactions.
//  ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - The chart of accounts for which you need to get the storno table.
//  ChartOfAccountsPeriod - Date - the period of access to the organization's chart of accounts setup, if the period of the registrar is not used
//  RegistrarPeriod - Boolean - indicates whether the transaction date is filled in with the date of the document being reversed.if not specified, the date
//                                is not filled in.
//
// Returns:
//   ValueTable - a table of transactions of transferred registrars with the reverse sign of the amounts and the type of transaction "Reverse" or "Reverse".
//
Function PostingsStorno(Recorders, ChartOfAccounts, ChartOfAccountsPeriod, RegistrarPeriod = False) Export
	
	Query = New Query;
	Query.Text = TransactionRequestText_();
	Query.SetParameter("DocumentsList", Recorders);
	Query.SetParameter("Ref", Documents.TransactionFinancialAccounting.EmptyRef());
	Query.SetParameter("DateEmpty", Date("00010101"));
	Query.SetParameter("RegistrarPeriod", RegistrarPeriod);
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	Query.SetParameter("ChartOfAccountsPeriod", ChartOfAccountsPeriod);
	
	Result = Query.Execute().Unload();
	
	FieldsDetails = RegisterFieldsDetails();
	InvertedFields = InvertedFields(FieldsDetails);
	InvertedResources = InvertedResources(FieldsDetails);
	
	For Each AccountingEntry In Result Do
		If AccountingEntry.ReplaceWithReverse Then
			InvertEntriy(AccountingEntry, InvertedFields, InvertedResources, FieldsDetails.ExtDimensionCount);
			AccountingEntry.PostingType = Enums.PostingTypesFinancialAccounting.Reverse;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Transaction processing procedures
//
// Parameters:
//  Postings - AccountingRegisterRecordSet.International - a set of processed register entries.
//
Procedure PerformAdditionalProcessingOfTransactions(Postings) Export
	
	FillInExtDimensionValuesThatAreNotFilledIn(Postings);
	
EndProcedure

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Internal

Function RegisterFieldsDetails() Export
	
	RegisterMetadata = CreateRecordSet().Metadata();
	
	FieldsDetails = New Structure();
	FieldsDetails.Insert("ExtDimensionCount",    RegisterMetadata.ChartOfAccounts.MaxExtDimensionCount);
	FieldsDetails.Insert("BalanceMeasurements",   New Array());
	FieldsDetails.Insert("UnbalancedMeasurements", New Array());
	FieldsDetails.Insert("BalanceSheetResources",     New Array());
	FieldsDetails.Insert("UnbalancedResources",   New Array());
	FieldsDetails.Insert("Attributes",             New Array());
	
	For Each Dimension In RegisterMetadata.Dimensions Do
		DimensionName = Dimension.Name;
		If StrStartsWith(DimensionName, "Delete") Then
		ElsIf Dimension.Balance Then
			FieldsDetails.BalanceMeasurements.Add(DimensionName);
		Else
			FieldsDetails.UnbalancedMeasurements.Add(DimensionName);
		EndIf;
	EndDo;
	
	For Each Resource In RegisterMetadata.Resources Do
		ResourceName = Resource.Name;
		If StrStartsWith(ResourceName, "Delete") Then
		ElsIf Resource.Balance Then
			FieldsDetails.BalanceSheetResources.Add(ResourceName);
		Else
			FieldsDetails.UnbalancedResources.Add(ResourceName);
		EndIf;
	EndDo;
	
	For Each Attribute In RegisterMetadata.Attributes Do
		AttributeName = Attribute.Name;
		If StrStartsWith(AttributeName, "Delete") Then
		ElsIf AttributeName = "FinRecordID" Then
		Else
			FieldsDetails.Attributes.Add(AttributeName);
		EndIf;
	EndDo;
	
	Return FieldsDetails;
	
EndFunction

Function InvertedFields(RegisterFieldsDetails) Export
	
	InvertedFields = New Array();
	InvertedFields.Add("Account");
	InvertedFields.Add("ExtDimension");
	InvertedFields.Add("ExtDimensionType");
	InvertedFields.Add("AccountCompliance");
	
	CommonClientServer.SupplementArray(InvertedFields, RegisterFieldsDetails.UnbalancedMeasurements);
	CommonClientServer.SupplementArray(InvertedFields, RegisterFieldsDetails.UnbalancedResources);
	
	Return InvertedFields;
	
EndFunction

Function InvertedResources(RegisterFieldsDetails) Export
	
	InvertedResources = Common.CopyRecursive(RegisterFieldsDetails.BalanceSheetResources);
	
	For Each ResourceName In RegisterFieldsDetails.UnbalancedResources Do
		InvertedResources.Add(ResourceName + "Dr");
		InvertedResources.Add(ResourceName + "Cr");
	EndDo;
	
	Return InvertedResources;
	
EndFunction

Procedure InvertEntriy(AccountingEntry, InvertedFields, InvertedResources, ExtDimensionCount) Export
	
	For Each FieldName In InvertedFields Do
		If FieldName = "ExtDimension" Or FieldName = "ExtDimensionType" Then
			For ExtDimensionNumber = 1 To ExtDimensionCount Do
				SimpleDr = AccountingEntry[FieldName + "Dr" + ExtDimensionNumber];
				AccountingEntry[FieldName + "Dr" + ExtDimensionNumber] = AccountingEntry[FieldName + "Cr" + ExtDimensionNumber];
				AccountingEntry[FieldName + "Cr" + ExtDimensionNumber] = SimpleDr;
			EndDo;
		Else
			SimpleDr = AccountingEntry[FieldName + "Dr"];
			AccountingEntry[FieldName + "Dr"] = AccountingEntry[FieldName + "Cr"];
			AccountingEntry[FieldName + "Cr"] = SimpleDr;
		EndIf;
	EndDo;
	
	For Each ResourceName In InvertedResources Do
		If ValueIsFilled(AccountingEntry[ResourceName]) Then
			AccountingEntry[ResourceName] = -AccountingEntry[ResourceName];
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Function TransactionRequestText_()
	
	Return
	"SELECT
	|	CASE
	|		WHEN &RegistrarPeriod
	|			THEN Postings.Period
	|		ELSE &DateEmpty
	|	END AS Period,
	|	CASE
	|		WHEN &Ref = UNDEFINED
	|			THEN Postings.Recorder
	|		ELSE &Ref
	|	END AS Recorder,
	|	Postings.Organization,
	|	Postings.AccountDr,
	|	Postings.DepartmentDr,
	|	Postings.LineOfBusinessDr,
	|	Postings.ExtDimensionTypeDr1 AS ExtDimensionTypeDr1,
	|	Postings.ExtDimensionDr1,
	|	Postings.ExtDimensionTypeDr2 AS ExtDimensionTypeDr2,
	|	Postings.ExtDimensionDr2,
	|	Postings.ExtDimensionTypeDr3 AS ExtDimensionTypeDr3,
	|	Postings.ExtDimensionDr3,
	|	Postings.AccountCr,
	|	Postings.DepartmentCr,
	|	Postings.LineOfBusinessCr,
	|	Postings.ExtDimensionTypeCr1 AS ExtDimensionTypeCr1,
	|	Postings.ExtDimensionCr1,
	|	Postings.ExtDimensionTypeCr2 AS ExtDimensionTypeCr2,
	|	Postings.ExtDimensionCr2,
	|	Postings.ExtDimensionTypeCr3 AS ExtDimensionTypeCr3,
	|	Postings.ExtDimensionCr3,
	|	Postings.CurrencyDr,
	|	-Postings.CurrencyAmountDr AS CurrencyAmountDr,
	|	Postings.CurrencyCr,
	|	-Postings.CurrencyAmountCr AS CurrencyAmountCr,
	|	-Postings.CountDr AS CountDr,
	|	-Postings.CountCr AS CountCr,
	|	-Postings.Sum AS Sum,
	|	-Postings.PresentationAmount AS PresentationAmount,
	|	VALUE(Enum.PostingTypesFinancialAccounting.ReversingEntry) AS PostingType,
	|	Postings.Content AS Content,
	|	Postings.AccountComplianceDr AS AccountComplianceDr,
	|	Postings.AccountComplianceCr AS AccountComplianceCr,
	|	CASE
	|		WHEN FinancialAccountingChartsOfAccountsForCompanies.PostingGenerationSetting IS NULL
	|			THEN FALSE
	|		WHEN FinancialAccountingChartsOfAccountsForCompanies.PostingGenerationSetting.MethodOfCancelingTransactions
	|			= VALUE(Enum.MethodsOfCancelingPostingsInFinancialAccounting.ByReversePostings)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ReplaceWithReverse
	|FROM
	|	AccountingRegister.International.RecordsWithExtDimensions(, , ChartOfAccounts = &ChartOfAccounts AND Recorder IN (&DocumentsList), , ) AS Postings
	|	LEFT JOIN InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS FinancialAccountingChartsOfAccountsForCompanies
	|		ON Postings.ChartOfAccounts = FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts
	|		 AND Postings.Organization = FinancialAccountingChartsOfAccountsForCompanies.Organization
	|WHERE
	|	CASE
	|		WHEN FinancialAccountingChartsOfAccountsForCompanies.Period IS NULL
	|			THEN TRUE
	|		ELSE FinancialAccountingChartsOfAccountsForCompanies.Period IN
	|			(SELECT
	|				MAX(BusinessAccountPlans.Period)
	|			FROM
	|				InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS BusinessAccountPlans
	|			WHERE
	|				BusinessAccountPlans.ChartOfAccounts = Postings.ChartOfAccounts
	|				AND BusinessAccountPlans.Organization = Postings.Organization
	|				AND BusinessAccountPlans.Period <= CASE
	|					WHEN &RegistrarPeriod
	|						THEN Postings.Period
	|					ELSE &ChartOfAccountsPeriod
	|				END
	|			)
	|	END
	|";
	
EndFunction

Procedure FillInExtDimensionValuesThatAreNotFilledIn(Postings)
	
	CacheOfEmptyValuesOfExtDimensionTypes = New Map;
	
	For Each AccountingEntry In Postings Do
		For Each ExtDimension In AccountingEntry.ExtDimensionsDr Do
			If Not ValueIsFilled(ExtDimension.Value) Then
				EmptyValue = EmptyExtdimensionValue(ExtDimension.Key, CacheOfEmptyValuesOfExtDimensionTypes);
				If ExtDimension.Value <> EmptyValue Then
					AccountingEntry.ExtDimensionsDr.Insert(ExtDimension.Key, EmptyValue);
				EndIf;
			EndIf;
		EndDo;
		
		For Each ExtDimension In AccountingEntry.ExtDimensionsCr Do
			If Not ValueIsFilled(ExtDimension.Value) Then
				EmptyValue = EmptyExtdimensionValue(ExtDimension.Key, CacheOfEmptyValuesOfExtDimensionTypes);
				If ExtDimension.Value <> EmptyValue Then
					AccountingEntry.ExtDimensionsCr.Insert(ExtDimension.Key, EmptyValue);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Function EmptyExtdimensionValue(ExtDimensionType, CacheOfEmptyValues)
	
	EmptyValue = CacheOfEmptyValues.Get(ExtDimensionType);
	
	If EmptyValue = Undefined Then
		EmptyValue = ExtDimensionType.ValueType.AdjustValue(Undefined);
		CacheOfEmptyValues.Insert(ExtDimensionType, EmptyValue);
	EndIf;
	
	Return EmptyValue;
	
EndFunction

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccountingRegisters.International.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("10c0321e-d92b-40ee-9f5b-9a0c77973c6b");
	Handler.Multithreaded = False;
	Handler.UpdateDataFillingProcedure = "AccountingRegisters.International.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật biểu ghi ""Sổ bút toán có đối ứng (Kế toán quốc tế)"":';
								|ru = 'Обновление регистра ""Журнал проводок с корреспонденцией (международный учет)"":';
								|en = 'Update the ""Ledger entry journal with correspondence (financial accounting)"" register:'; fa = 'Update the ""Ledger entry journal with correspondence (financial accounting)"" register:';
								|it = 'Update the ""Ledger entry journal with correspondence (financial accounting)"" register:';
								|pl = 'Update the ""Ledger entry journal with correspondence (financial accounting)"" register:';
								|tr = '""Çift taraflı muhasebe defteri (uluslararası muhasebe)"" kaydının güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = 'Chuyển các giá trị khoản mục chưa được điền thành các giá trị rỗng theo kiểu dữ liệu';
								|ru = '- Приведение незаполненных значений субконто к пустым значениям типов';
								|en = '- Convert unfilled extra dimension values to empty type values'; fa = '- Convert unfilled extra dimension values to empty type values';
								|it = '- Convert unfilled extra dimension values to empty type values';
								|pl = '- Convert unfilled extra dimension values to empty type values';
								|tr = '- Doldurulmamış alt hesap değerlerinin boş tip değerlerine getirilmesi'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array();
	ItemsToRead.Add(Metadata.AccountingRegisters.International.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array();
	Editable1.Add(Metadata.AccountingRegisters.International.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array();
	ToLock.Add(Metadata.AccountingRegisters.International.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Data logging handler for updates
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	RegisterMetadata = Metadata.AccountingRegisters.International;
	FullRegisterName = RegisterMetadata.FullName();
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();
	
	Query.Text = "
	|SELECT
	|	FinancialExtraDimensionTypes.Ref AS ExtDimensionType,
	|	FinancialExtraDimensionTypes.ValueType AS ValueType
	|FROM
	|	ChartOfCharacteristicTypes.FinancialExtraDimensionTypes AS FinancialExtraDimensionTypes
	|";
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	AllEmptyValues = New Array();
	TypesOfEmptyValues = New Array();
	
	While Selection.Next() Do
		ValueType = Selection.ValueType;
		EmptyValue = ValueType.AdjustValue(Undefined);
		
		If AllEmptyValues.Find(EmptyValue) = Undefined Then
			AllEmptyValues.Add(EmptyValue);
			TypesOfEmptyValues.Add(TypeOf(EmptyValue));
		EndIf;
	EndDo;
	
	If AllEmptyValues.Find(Undefined) = Undefined Then
		AllEmptyValues.Add(Undefined);
	EndIf;
	
	EmptyExtDimensionValues = New ValueTable();
	EmptyExtDimensionValues.Columns.Add("ExtDimensionType", New TypeDescription("ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes"));
	EmptyExtDimensionValues.Columns.Add("Value", New TypeDescription(TypesOfEmptyValues));
	
	Selection.Reset();
	
	While Selection.Next() Do
		ExtDimensionType = Selection.ExtDimensionType;
		ValueType = Selection.ValueType;
		EmptyValue = ValueType.AdjustValue(Undefined);
		
		NewRow = EmptyExtDimensionValues.Add();
		NewRow.ExtDimensionType = ExtDimensionType;
		NewRow.Value = EmptyValue;
	EndDo;
	
	Query.SetParameter("AllEmptyValues", AllEmptyValues);
	Query.SetParameter("EmptyExtDimensionValues", EmptyExtDimensionValues);
	Query.SetParameter("PointInTime", New PointInTime('00010101'));
	
	Query.Text = "
	|SELECT
	|	EmptyExtDimensionValues.ExtDimensionType AS ExtDimensionType,
	|	EmptyExtDimensionValues.Value AS Value
	|INTO TTEmptyExtDimensionValues
	|FROM
	|	&EmptyExtDimensionValues AS EmptyExtDimensionValues
	|INDEX BY
	|	ExtDimensionType,
	|	Value
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InternationalExtDimension.Recorder AS Recorder,
	|	InternationalExtDimension.PointInTime AS PointInTime
	|INTO TTRecordersOfEmptyExtDimension
	|FROM
	|	AccountingRegister.International.ExtDimensions AS InternationalExtDimension
	|WHERE
	|	InternationalExtDimension.Value IN (&AllEmptyValues)
	|	AND TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTEmptyExtDimensionValues AS EmptyExtDimensionValues
	|		WHERE
	|			EmptyExtDimensionValues.ExtDimensionType = InternationalExtDimension.Type
	|			AND EmptyExtDimensionValues.Value <> InternationalExtDimension.Value
	|		)
	|GROUP BY
	|	InternationalExtDimension.Recorder,
	|	InternationalExtDimension.PointInTime
	|INDEX BY
	|	Recorder
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RecordersOfEmptyExtDimension.Recorder AS Recorder,
	|	RecordersOfEmptyExtDimension.PointInTime AS PointInTime
	|INTO TTVariousRecordersOfEmptyExtDimension
	|FROM
	|	TTRecordersOfEmptyExtDimension AS RecordersOfEmptyExtDimension
	|WHERE
	|	NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTRecordersOfEmptyExtDimension AS RecordersOtherPeriods
	|		WHERE
	|			RecordersOtherPeriods.Recorder = RecordersOfEmptyExtDimension.Recorder
	|			AND RecordersOtherPeriods.PointInTime < RecordersOfEmptyExtDimension.PointInTime
	|		)
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTRecordersOfEmptyExtDimension
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTEmptyExtDimensionValues
	|";
	
	Result = Query.Execute();
	
	Query.Text = "
	|SELECT TOP 1000
	|	RecordersOfEmptyExtDimension.Recorder AS Recorder,
	|	RecordersOfEmptyExtDimension.PointInTime AS PointInTime
	|FROM
	|	TTVariousRecordersOfEmptyExtDimension AS RecordersOfEmptyExtDimension
	|WHERE
	|	RecordersOfEmptyExtDimension.PointInTime > &PointInTime
	|ORDER BY
	|	RecordersOfEmptyExtDimension.PointInTime
	|";
	
	Result = Query.Execute();
	
	While Not Result.IsEmpty() Do
		ResultTable2 = Result.Unload();
		Recorders = ResultTable2.UnloadColumn("Recorder");
		
		InfobaseUpdate.MarkRecordersForProcessing(Parameters, Recorders, FullRegisterName);
		
		RowsCount = ResultTable2.Count();
		Query.SetParameter("PointInTime", ResultTable2[RowsCount - 1]["PointInTime"]);
		Result = Query.Execute();
	EndDo;
	
EndProcedure

// The update handler
// 
// Parameters:
//  Parameters - Structure - Handler Parameters:
//   * SubsystemVersionAtStartUpdates - String - the version of the subsystem.
//   * HandlerName - String - name of the handler.
//   * UpdatedData - Structure
//   * ProcessingCompleted - Boolean, Undefined - indicates End of processing.
//   * Queue - Number - the queue.
//   * ExecutionProgress - Structure:
//     ** TotalObjectCount - Number - total objects processed.
//     ** ProcessedObjectsCount1 - Number - processed objects.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	
	RegisterMetadata = Metadata.AccountingRegisters.International;
	FullRegisterName = RegisterMetadata.FullName();
	FullDocumentName = Undefined;
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingDataSelectionParameters();
	AdditionalParameters.TempTableName = "TTDataToProcess";
	AdditionalParameters.SelectInBatches = False;
	
	TempTablesManager = New TempTablesManager();
	
	ResultOfCreatingTable = InfobaseUpdate.CreateTemporaryTableOfRegisterRecordersToProcess(
		Parameters.Queue,
		FullDocumentName,
		FullRegisterName,
		TempTablesManager,
		AdditionalParameters);
	
	If Not ResultOfCreatingTable.HasRecordsInTemporaryTable Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(
			Parameters.Queue, FullRegisterName);
		Return;
	EndIf;
	
	ObjectsProcessed = 0;
	ExceptionsWhenUpdating = New Array();
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = "
	|SELECT
	|	DataForProcessing.Recorder AS Recorder
	|FROM
	|	TTDataToProcess AS DataForProcessing
	|";
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		ExceptionReason = "";
		Recommendation = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = "Block";
			
			Block = New DataLock();
			LockItem = Block.Add(FullRegisterName + ".RecordSet");
			LockItem.SetValue("Recorder", Selection.Recorder);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			ExceptionReason = "BadData"; 
			
			RecordSet = CreateRecordSet();
			RecordSet.Filter.Recorder.Set(Selection.Recorder);
			RecordSet.Read();
			
			FillInExtDimensionValuesThatAreNotFilledIn(RecordSet);
			
			ExceptionReason = "Record";
			
			If RecordSet.Modified() Then
				InfobaseUpdate.WriteData(RecordSet);
			Else
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Recorder);
			
			If ExceptionReason = "BadData" Or ExceptionReason = "Record" Then
				IssueDetails = InfobaseUpdateTM.DataProblem(
					Selection.Recorder, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
			EndIf;
			
		EndTry;
		
	EndDo;
	
	If ObjectsProcessed > 0 Then
		InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
	EndIf;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
	
EndProcedure

#EndRegion

#EndRegion


#EndIf
