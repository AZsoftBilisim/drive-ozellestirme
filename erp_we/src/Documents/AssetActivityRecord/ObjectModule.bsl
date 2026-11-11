#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		If FillingData.Property("DocumentBasis") And TypeOf(FillingData.DocumentBasis) = Type("Array") Then
			
			FillInBasedOnArrayOfOrders(FillingData.DocumentBasis);
			
		Else
			
			FillPropertyValues(ThisObject, FillingData);
			
		EndIf;
		
	ElsIf FillInDataType = Type("CatalogRef.Assets")
		Or FillInDataType = Type("CatalogRef.SubAssets")
		Then
		
		FillInDocumentBasedOnObjectOfOperation(FillingData);
		
	EndIf;
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NotCheckedAttributeArray.Add("RunningTime.Asset");
	
	Documents.AssetActivityRecord.CheckingTableOfDevelopments(ThisObject, RunningTime, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If GetFunctionalOption("UseRMManagement") Then
		
		CalculateDailyAverages();
		
	EndIf;
	
	EstimatedRunningTimeValues.Clear();
	CalculateDependentPerformanceIndicators(RunningTime);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

// Initializes the document
//
Procedure InitializeDocument(FillingData = Undefined)
	
	Date = CurrentSessionDate();
	EmployeeResponsible = Users.CurrentUser();
	
EndProcedure

// Fills in a document based on an array
//
Procedure FillInBasedOnArrayOfOrders(ReferenceArray)
	
	RunningTime.Clear();
	For Each ReferenceOrder In ReferenceArray Do
		NewRow = RunningTime.Add();
		FillPropertyValues(NewRow, ReferenceOrder);
	EndDo;
	
EndProcedure

// Fills in the document based on the object 
//
Procedure FillInDocumentBasedOnObjectOfOperation(FillingData)
	
	RunningTime.Clear();
	
	SetPrivilegedMode(True);
	
	QueryText = RunningTimeRegistrationLocalization.TextOfRequestToFillInDocumentBasedOnObjectOfOperation();
	
	If QueryText = Undefined Then
		
		QueryText =
		"
		|SELECT
		|	Objects.Ref AS Asset,
		|	ISNULL(RunningTimeValues.RunningTimeValue, VALUE(Catalog.RunningTimeValues.EmptyRef)) AS RunningTimeValue,
		|	Objects.Status AS Status,
		|	CASE
		|		WHEN Objects.Status = VALUE(Enum.AssetStatuses.InOperation)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsStatus,
		|	Objects.DeletionMark AS ThereAreErrorsRemoved,
		|	Objects.IsFolder AS ThereAreErrorsGroup
		|FROM
		|	Catalog.Assets AS Objects
		|		LEFT JOIN Catalog.MaintenanceSchemes.RunningTimeValues AS RunningTimeValues
		|		ON Objects.Class = RunningTimeValues.Ref
		|			AND (NOT RunningTimeValues.RegisterBySource)
		|WHERE
		|	Objects.Ref = &Asset AND &UseRMManagement
		|
		|UNION ALL
		|
		|SELECT
		|	Objects.Ref AS Asset,
		|	ISNULL(FixedAssetsAccountingProcedure.RunningTimeValue, VALUE(Catalog.RunningTimeValues.EmptyRef)) AS RunningTimeValue,
		|	Objects.Status AS Status,
		|	FALSE AS ThereAreErrorsStatus,
		|	Objects.DeletionMark AS ThereAreErrorsRemoved,
		|	Objects.IsFolder AS ThereAreErrorsGroup
		|FROM
		|	Catalog.Assets AS Objects
		|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
		|				&Date, 
		|				CorrectionDate = DATETIME(1,1,1)
		|					AND FixedAsset IN (&Asset)) AS FixedAssetsAccountingProcedure
		|		ON Objects.Ref = FixedAssetsAccountingProcedure.FixedAsset
		|WHERE
		|	Objects.Ref = &Asset AND NOT &UseRMManagement
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Nodes.Ref AS Asset,
		|	ISNULL(RunningTimeValues.RunningTimeValue, VALUE(Catalog.RunningTimeValues.EmptyRef)) AS RunningTimeValue,
		|	Nodes.Status AS Status,
		|	CASE
		|		WHEN Nodes.Status = VALUE(Enum.AssetStatuses.InOperation)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsStatus,
		|	Nodes.DeletionMark AS ThereAreErrorsRemoved
		|FROM
		|	Catalog.SubAssets AS Nodes
		|		LEFT JOIN Catalog.MaintenanceSchemes.RunningTimeValues AS RunningTimeValues
		|		ON Nodes.Class = RunningTimeValues.Ref
		|			AND (NOT RunningTimeValues.RegisterBySource)
		|WHERE
		|	Nodes.Ref = &Asset
		|";
		
	EndIf; 
	
	Query = New Query(QueryText);
	Query.SetParameter("Asset", FillingData);
	Query.SetParameter("Date", ?(ValueIsFilled(Date), Date, CurrentSessionDate()));
	Query.SetParameter("UseRMManagement", GetFunctionalOption("UseRMManagement"));
	Query.SetParameter("VNAManagementIsUsed_2_4", NonCurrentAssets.VNAManagementIsUsed_2_4(Date));
	
	ErrorTextGroup_ = NStr("vi = 'Mục danh mục ''''%1'''' là một nhóm. Nhập trên cơ sở nhóm danh mục bị cấm.';
							|ru = 'Элемент справочника ""%1"" является группой. Ввод на основании групп справочника запрещен.';
							|en = '""%1"" is a group. Cannot generate documents from a group.'; fa = '""%1"" is a group. Cannot generate documents from a group.';
							|it = 'L''elemento di riferimento ""%1"" è un gruppo. L''immissione sulla base di gruppi di directory è proibita.';
							|pl = 'Element  katalogu ""%1"" jest grupa. Wprowadzenie na podstawie grup katalogu jest zabronione.';
							|tr = 'Dizin öğesi ""%1"" bir gruptur. Dizin gruplarına dayalı giriş yasaktır.'");
	ErrorTextDeleted = NStr("vi = '%1 ""%2"" được đánh dấu để xóa. Nhập trên cơ sở một mục của danh mục được đánh dấu để xóa bị cấm.';
							|ru = '%1 ""%2"" помечен на удаление. Ввод на основании помеченного на удаление элемента справочника запрещен.';
							|en = '%1 ""%2"" is marked for deletion. Cannot generate documents from items that have been marked for deletion.'; fa = '%1 ""%2"" is marked for deletion. Cannot generate documents from items that have been marked for deletion.';
							|it = '%1 ""%2"" è stato selezionato per l''eliminazione. L''inserimento sulla base dell''elemento della directory contrassegnato per l''eliminazione è proibita.';
							|pl = '%1 ""%2"" zaznaczono do usunięcia. Wprowadzenie na podstawie zaznaczonego do usunięcia elementu katalogu jest zabronione.';
							|tr = '%1 ""%2"" silinmek üzere işaretlendi. Silinmek üzere işaretlenmiş bir dizin öğesi temelinde giriş yasaktır.'");
	ErrorTextStatus = NStr("vi = '%1 ""%2"" ở trạng thái ""%3"". Nhập trên cơ sở chỉ được phép trong trạng thái ""Đang sử dụng"".';
							|ru = '%1 ""%2"" находится в статусе ""%3"". Ввод на основании разрешен только в статусе ""В эксплуатации"".';
							|en = '%1 ""%2"" in ""%3"" status. To generate a document, change its status to ""Operating"".'; fa = '%1 ""%2"" in ""%3"" status. To generate a document, change its status to ""Operating"".';
							|it = '%1 ""%2"" si trova nello stato ""%3"". L''immissione in base alla causale è permessa solo nello stato ""In uso"".';
							|pl = '%1 ""%2"" ma status  ""%3"". Wprowadzenie na podstawie jest dozwolony tylko ze statusem ""W eksploatacji"".';
							|tr = '%1 ""%2"" ""%3"" durumundadır. Temelde girişe yalnızca ""İşlemde"" durumunda izin verilir.'");
	ErrorTextIndicator = NStr("vi = 'Đối với %1 ""%2"", không có chỉ số sản lượng để đăng ký';
								|ru = 'Для %1 ""%2"" нет доступных для регистрации показателей наработки';
								|en = '%1 ""%2"" has no operating time units to register'; fa = '%1 ""%2"" has no operating time units to register';
								|it = 'Per %1 ""%2"" non ci sono indicatori di tempi senza guasti disponibili per la registrazione';
								|pl = 'Dla %1 ""%2"" nie ma dostępnych dla rejestracji wskaźników średniego czasu pracy';
								|tr = '%1 ""%2"" için günlük kaydı için kullanılabilir çalışma zamanı değerleri yok'");
	
	SetPrivilegedMode(True);
	Package = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	If Not Package[0].IsEmpty() Then
		
		Selection = Package[0].Select();
		
		While Selection.Next() Do
			If Selection.ThereAreErrorsGroup Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextGroup_,
					Selection.Asset);
				Raise ErrorText;
			ElsIf Selection.ThereAreErrorsRemoved Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextDeleted,
					NStr("vi = 'tài sản đang vận hành';
						|ru = 'объекта эксплуатации';
						|en = 'Asset'; fa = 'دارایی';
						|it = 'Oggetto in uso';
						|pl = 'obiektu eksploatacji';
						|tr = 'varlık'"),
					Selection.Asset);
				Raise ErrorText;
			ElsIf Selection.ThereAreErrorsStatus Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextStatus,
					NStr("vi = 'tài sản đang vận hành';
						|ru = 'объекта эксплуатации';
						|en = 'Asset'; fa = 'دارایی';
						|it = 'Oggetto in uso';
						|pl = 'obiektu eksploatacji';
						|tr = 'varlık'"),
					Selection.Asset,
					Selection.Status);
				Raise ErrorText;
			ElsIf Not ValueIsFilled(Selection.RunningTimeValue) Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextIndicator,
					NStr("vi = 'tài sản đang vận hành';
						|ru = 'объекта эксплуатации';
						|en = 'asset'; fa = 'asset';
						|it = 'Oggetto in uso';
						|pl = 'obiektu eksploatacji';
						|tr = 'varlık'"),
					Selection.Asset);
				Raise ErrorText;
			EndIf;
			
			FillPropertyValues(RunningTime.Add(), Selection);
		EndDo;
		
	EndIf;
	
	If Not Package[1].IsEmpty() Then
		Selection = Package[1].Select();
		While Selection.Next() Do
			If Selection.ThereAreErrorsRemoved Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextDeleted,
					NStr("vi = 'các chi tiết máy của tài sản đang vận hành';
						|ru = 'узла объекта эксплуатации';
						|en = 'Sub-asset'; fa = 'زیردارایی';
						|it = 'Nodi oggetto in uso';
						|pl = 'węzeł obiektu eksploatacji';
						|tr = 'alt varlık'"),
					Selection.Asset);
				Raise ErrorText;
			ElsIf Selection.ThereAreErrorsStatus Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextStatus,
					NStr("vi = 'các chi tiết máy của tài sản đang vận hành';
						|ru = 'узла объекта эксплуатации';
						|en = 'Sub-asset'; fa = 'زیردارایی';
						|it = 'Nodi oggetto in uso';
						|pl = 'węzeł obiektu eksploatacji';
						|tr = 'alt varlık'"),
					Selection.Asset,
					Selection.Status);
				Raise ErrorText;
			ElsIf Not ValueIsFilled(Selection.RunningTimeValue) Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextIndicator,
					NStr("vi = 'các chi tiết máy của tài sản đang vận hành';
						|ru = 'узла объекта эксплуатации';
						|en = 'Sub-asset'; fa = 'زیردارایی';
						|it = 'Nodi oggetto in uso';
						|pl = 'węzeł obiektu eksploatacji';
						|tr = 'alt varlık'"),
					Selection.Asset);
				Raise ErrorText;
			EndIf;
			FillPropertyValues(RunningTime.Add(), Selection);
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CalculateDependentPerformanceIndicators(TablePartSource, RowsArray = Undefined)
	
	If Not GetFunctionalOption("UseRMManagement") Then
		Return;
	EndIf;
		
	QueryText =
	"SELECT
	|	DocumentTable.Asset AS Asset,
	|	CAST(DocumentTable.RunningTimeValue AS Catalog.RunningTimeValues) AS RunningTimeValue,
	|	CAST(DocumentTable.Value AS NUMBER) AS Value,
	|	CAST(DocumentTable.AverageDailyValue AS NUMBER) AS AverageDailyValue
	|
	|INTO DocumentTable
	|
	|FROM
	|	&DocumentTable AS DocumentTable
	|
	|INDEX BY
	|	Asset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountingParameters.Ref AS Asset,
	|	AccountingParameters.RunningTimeValue AS RunningTimeValue,
	|	DocumentTable.Value + AccountingParameters.ValueOffset AS Value,
	|	DocumentTable.AverageDailyValue AS AverageDailyValue
	|FROM
	|	DocumentTable AS DocumentTable
	|
	|		INNER JOIN Catalog.Assets.RunningTimeRecordingParameters AS AccountingParameters
	|		ON DocumentTable.Asset = AccountingParameters.SourceOfParameter
	|			AND DocumentTable.RunningTimeValue = AccountingParameters.RunningTimeValue
	|
	|WHERE
	|	AccountingParameters.Ref.Status IN (VALUE(Enum.AssetStatuses.InOperation))
	|
	|UNION ALL
	|
	|SELECT
	|	AccountingParameters.Ref,
	|	AccountingParameters.RunningTimeValue,
	|	DocumentTable.Value + AccountingParameters.ValueOffset,
	|	DocumentTable.AverageDailyValue
	|FROM
	|	DocumentTable AS DocumentTable
	|
	|		INNER JOIN Catalog.SubAssets.RunningTimeRecordingParameters AS AccountingParameters
	|		ON DocumentTable.Asset = AccountingParameters.SourceOfParameter
	|			AND DocumentTable.RunningTimeValue = AccountingParameters.RunningTimeValue
	|
	|WHERE
	|	AccountingParameters.Ref.Status IN (VALUE(Enum.AssetStatuses.InOperation))
	|	AND &UseNodes
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentTable", TablePartSource.Unload(RowsArray, "Asset, RunningTimeValue, Value, AverageDailyValue"));
	Query.SetParameter("UseNodes", GetFunctionalOption("UseSubAssets"));
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	ArrayOfAddedRows = New Array;
	Selection = Result.Select();
	While Selection.Next() Do
		
		NewRow = EstimatedRunningTimeValues.Add();
		FillPropertyValues(NewRow, Selection);
		
		ArrayOfAddedRows.Add(NewRow);
		
	EndDo;
	
	CalculateDependentPerformanceIndicators(EstimatedRunningTimeValues, ArrayOfAddedRows);
	
EndProcedure

// Calculates the average daily values of earnings indicators
//
Procedure CalculateDailyAverages()
	
	Query = New Query(
		"SELECT
		|	CAST(DocumentTable.LineNumber - 1 AS NUMBER) AS RowIndex,
		|	DocumentTable.Asset AS Asset,
		|	CAST(DocumentTable.RunningTimeValue AS Catalog.RunningTimeValues) AS RunningTimeValue,
		|	CAST(DocumentTable.Value AS NUMBER) AS Value
		|INTO TabularSectionData
		|FROM
		|	&DocumentTable AS DocumentTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentTable.RowIndex AS RowIndex,
		|	ISNULL(Objects.Ref, Nodes.Ref) AS Asset,
		|	DocumentTable.RunningTimeValue AS RunningTimeValue,
		|	DocumentTable.Value AS Value
		|INTO DocumentTable
		|FROM
		|	TabularSectionData AS DocumentTable
		|		LEFT JOIN Catalog.Assets AS Objects
		|		ON DocumentTable.Asset = Objects.Ref
		|		LEFT JOIN Catalog.SubAssets AS Nodes
		|		ON DocumentTable.Asset = Nodes.Ref
		|
		|INDEX BY
		|	Asset,
		|	RunningTimeValue
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ObjectSettings.Asset AS Asset,
		|	ObjectSettings.RunningTimeValue AS RunningTimeValue,
		|	ObjectSettings.AverageDailyValue
		|INTO ObjectSettings
		|FROM
		|	InformationRegister.AssetActivityRecords.SliceLast(
		|			&RegistrationDate,
		|			(Asset, RunningTimeValue) IN
		|				(SELECT
		|					DocumentTable.Asset,
		|					DocumentTable.RunningTimeValue
		|				FROM
		|					DocumentTable AS DocumentTable)) AS ObjectSettings
		|
		|INDEX BY
		|	Asset,
		|	RunningTimeValue
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentTable.RowIndex AS RowIndex,
		|	DocumentTable.Asset AS Asset,
		|	DocumentTable.RunningTimeValue AS RunningTimeValue,
		|	DocumentTable.Value AS Value,
		|	ISNULL(ObjectSettings.AverageDailyValue, 0) AS DefaultDailyAverage,
		|	ISNULL(ClassSettings.RecalculateAverageDailyValue, FALSE) AS RecalculateAverageDailyValue,
		|	ENDOFPERIOD(DATEADD(&RegistrationDate, DAY, -ISNULL(ClassSettings.MinimumCalculationPeriod, 0)), DAY) AS MinimumPeriod,
		|	BEGINOFPERIOD(DATEADD(&RegistrationDate, DAY, -ISNULL(ClassSettings.MaximumCalculationPeriod, 0)), DAY) AS MaximumPeriod,
		|	ISNULL(DatesOfAdjustmentRecords.Period, DATETIME(1, 1, 1)) AS DateOfCorrectionEntry
		|INTO Parameters
		|FROM
		|	DocumentTable AS DocumentTable
		|		LEFT JOIN Catalog.MaintenanceSchemes.RunningTimeValues AS ClassSettings
		|		ON DocumentTable.Asset.Class = ClassSettings.Ref
		|			AND DocumentTable.RunningTimeValue = ClassSettings.RunningTimeValue
		|		LEFT JOIN ObjectSettings AS ObjectSettings
		|		ON DocumentTable.Asset = ObjectSettings.Asset
		|			AND DocumentTable.RunningTimeValue = ObjectSettings.RunningTimeValue
		|		LEFT JOIN InformationRegister.AssetActivityRecords.SliceLast(
		|				&RegistrationDate,
		|				CorrectiveEntry
		|					AND (Asset, RunningTimeValue) IN
		|						(SELECT
		|							DocumentTable.Asset,
		|							DocumentTable.RunningTimeValue
		|						FROM
		|							DocumentTable AS DocumentTable)) AS DatesOfAdjustmentRecords
		|		ON DocumentTable.Asset = DatesOfAdjustmentRecords.Asset
		|			AND DocumentTable.RunningTimeValue = DatesOfAdjustmentRecords.RunningTimeValue
		|
		|INDEX BY
		|	Asset,
		|	RunningTimeValue
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MIN(RunningTime.Period) AS Period,
		|	RunningTime.Asset AS Asset,
		|	RunningTime.RunningTimeValue AS RunningTimeValue
		|INTO RecordsOfPeriods
		|FROM
		|	InformationRegister.AssetActivityRecords AS RunningTime
		|		INNER JOIN Parameters AS Parameters
		|		ON RunningTime.Asset = Parameters.Asset
		|			AND RunningTime.RunningTimeValue = Parameters.RunningTimeValue
		|			AND RunningTime.Period <= Parameters.MinimumPeriod
		|			AND RunningTime.Period >= Parameters.MaximumPeriod
		|			AND RunningTime.Period >= Parameters.DateOfCorrectionEntry
		|WHERE
		|	Parameters.RecalculateAverageDailyValue
		|
		|GROUP BY
		|	RunningTime.Asset,
		|	RunningTime.RunningTimeValue
		|
		|INDEX BY
		|	Asset,
		|	RunningTimeValue
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Parameters.RowIndex,
		|	CASE
		|		WHEN NOT Parameters.RecalculateAverageDailyValue
		|			THEN Parameters.DefaultDailyAverage
		|		WHEN AssetActivityRecords.Period IS NULL 
		|			THEN Parameters.DefaultDailyAverage
		|		WHEN DATEDIFF(AssetActivityRecords.Period, &RegistrationDate, DAY) = 0
		|			THEN Parameters.DefaultDailyAverage
		|		ELSE (Parameters.Value - AssetActivityRecords.Value) / DATEDIFF(AssetActivityRecords.Period, &RegistrationDate, DAY)
		|	END AS AverageDailyValue
		|FROM
		|	Parameters AS Parameters
		|		LEFT JOIN RecordsOfPeriods AS RecordsOfPeriods
		|			LEFT JOIN InformationRegister.AssetActivityRecords AS AssetActivityRecords
		|			ON RecordsOfPeriods.Period = AssetActivityRecords.Period
		|				AND RecordsOfPeriods.Asset = AssetActivityRecords.Asset
		|				AND RecordsOfPeriods.RunningTimeValue = AssetActivityRecords.RunningTimeValue
		|		ON Parameters.Asset = RecordsOfPeriods.Asset
		|			AND Parameters.RunningTimeValue = RecordsOfPeriods.RunningTimeValue");
	
	Query.SetParameter("DocumentTable", RunningTime.Unload( , "LineNumber, Asset, RunningTimeValue, Value"));
	Query.SetParameter("RegistrationDate", Date);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		For Each String In RunningTime Do
			String.AverageDailyValue = 0;
		EndDo;
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
		FillPropertyValues(RunningTime[Selection.RowIndex], Selection);
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
