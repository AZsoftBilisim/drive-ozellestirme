#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	BasisType = TypeOf(FillingData);
	
	If BasisType = Type("CatalogRef.Assets")
		Or BasisType = Type("CatalogRef.SubAssets") Then
		
		FillInBasedOnObjectOfOperation(FillingData);
		
	EndIf;
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
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

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NotCheckedAttributeArray.Add("RunningTime.Asset");
	
	Documents.AssetActivityRecord.CheckingTableOfDevelopments(ThisObject, RunningTime, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region Private

// Initializes the document
//
Procedure InitializeDocument(FillingData = Undefined)
	
	Date = CurrentSessionDate();
	EmployeeResponsible = Users.CurrentUser();
	
EndProcedure

// Fills in the document based on the object 
//
Procedure FillInBasedOnObjectOfOperation(FillingData)
	
	RunningTime.Clear();
	
	SetPrivilegedMode(True);
	
	ListOfRequests = New Array;
	
	ListOfRequestsObjects = New Array;

	UseRMManagement = False;
	UseRMManagement = GetFunctionalOption("UseRMManagement");
	If UseRMManagement Then
		QueryText =
		"SELECT
		|	Objects.Ref AS Asset,
		|	ISNULL(RunningTimeValues.RunningTimeValue, VALUE(Catalog.RunningTimeValues.EmptyRef)) AS RunningTimeValue,
		|	Objects.Status AS Status,
		|	CASE
		|		WHEN Objects.Status = VALUE(Enum.AssetStatuses.IsBeingEdited)
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
		|	Objects.Ref IN (&Asset)";
		ListOfRequestsObjects.Add(QueryText);
	Else

		QueryText =
		"SELECT
		|	Objects.Ref AS Asset,
		|	ISNULL(FixedAssetsAccountingProcedure.RunningTimeValue, VALUE(Catalog.RunningTimeValues.EmptyRef)) AS RunningTimeValue,
		|	Objects.Status AS Status,
		|	FALSE AS ThereAreErrorsStatus,
		|	Objects.DeletionMark AS ThereAreErrorsRemoved,
		|	Objects.IsFolder AS ThereAreErrorsGroup
		|FROM
		|	Catalog.Assets AS Objects
		|		
		|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
		|				&Date, 
		|				CorrectionDate = DATETIME(1,1,1)
		|					AND FixedAsset IN (&Asset)) AS FixedAssetsAccountingProcedure
		|		ON Objects.Ref = FixedAssetsAccountingProcedure.FixedAsset
		|WHERE
		|	Objects.Ref IN (&Asset)";
			
		ListOfRequestsObjects.Add(QueryText);
		
	EndIf; 
	
	QueryText = StrConcat(ListOfRequestsObjects, TMCommonUse.QuerySeparatorInJoin());
	ListOfRequests.Add(QueryText);
	QueryText =
	"SELECT
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
	|	Nodes.Ref = &Asset";
	ListOfRequests.Add(QueryText);
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.SetParameter("Asset", FillingData);
	Query.SetParameter("Date", ?(ValueIsFilled(Date), Date, CurrentSessionDate()));
	Query.SetParameter("VNAManagementIsUsed_2_4", NonCurrentAssets.VNAManagementIsUsed_2_4(Date));
	
	ErrorTextGroup_ = NStr("vi = 'Mục danh mục ''''%1'''' là một nhóm. Nhập trên cơ sở nhóm danh mục bị cấm.';
							|ru = 'Элемент справочника ""%1"" является группой. Ввод на основании групп справочника запрещен.';
							|en = '""%1"" is a group. Cannot generate documents from a group.'; fa = '""%1"" is a group. Cannot generate documents from a group.';
							|it = 'L''elemento di riferimento ""%1"" è un gruppo. L''immissione sulla base di gruppi di directory è proibita.';
							|pl = 'Element  katalogu ""%1"" jest grupa. Wprowadzenie na podstawie grup katalogu jest zabronione.';
							|tr = 'Dizin öğesi ""%1"" bir gruptur. Dizin gruplarına dayalı giriş yasaktır.'");
	ErrorTextDeleted = NStr("vi = '%1 ""%2"" được đánh dấu để xóa. Nhập dựa trên một mục thư mục được đánh dấu để xóa bị cấm.';
							|ru = '%1 ""%2"" помечен на удаление. Ввод на основании помеченного на удаление элемента справочника запрещен.';
							|en = '%1 ""%2"" is marked for deletion. Cannot generate documents from items that have been marked for deletion.'; fa = '%1 ""%2"" is marked for deletion. Cannot generate documents from items that have been marked for deletion.';
							|it = '%1 ""%2"" è stato selezionato per l''eliminazione. L''inserimento sulla base dell''elemento della directory contrassegnato per l''eliminazione è proibita.';
							|pl = '%1 ""%2"" zaznaczono do usunięcia. Wprowadzenie na podstawie zaznaczonego do usunięcia elementu katalogu jest zabronione.';
							|tr = '%1 ""%2"" silinmek üzere işaretlendi. Silinmek üzere işaretlenmiş bir dizin öğesi temelinde giriş yasaktır.'");
	ErrorTextStatus = NStr("vi = '%1 ""%2"" ở trạng thái ""%3"". Nhập trên cơ sở chỉ được phép trong trạng thái ""Chỉnh sửa"".';
							|ru = '%1 ""%2"" находится в статусе ""%3"". Ввод на основании разрешен только в статусе ""Редактируется"".';
							|en = '%1 ""%2"" in ""%3"" status. To generate a document, change its status to ""Under development"".'; fa = '%1 ""%2"" in ""%3"" status. To generate a document, change its status to ""Under development"".';
							|it = '%1 ""%2"" si trova nello stato ""%3"". L''immissione nella causale è permessa solo nello stato ""In modifica""';
							|pl = '%1 ""%2"" ma status  ""%3"". Wprowadzenie na podstawie jest dozwolony tylko ze statusem ""Edytowany"".';
							|tr = '%1 ""%2"" ""%3"" durumundadır. Temelde girişe yalnızca ""redaksiyonda"" durumunda izin verilir.'");
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

#EndRegion

#EndIf
