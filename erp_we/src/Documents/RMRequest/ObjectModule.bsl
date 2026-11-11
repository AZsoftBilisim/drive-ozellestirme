#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("CatalogRef.Assets")
		Or FillInDataType = Type("CatalogRef.SubAssets") Then
		
		FillInDocumentBasedOnObjectOfOperation(FillingData);
		
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
	
	If Not IsNew() Then
		AttributesValuesBeforeChange = Common.ObjectAttributesValues(Ref, 
			"Date");
	Else
		AttributesValuesBeforeChange = New Structure("Date", Date(1,1,1,0,0,0));
	EndIf;
	
	If IsNew() Or Date <> AttributesValuesBeforeChange.Date Then
		
		UpdateDate = Date;
		If Date < UpdateDate Then
			
			ErrorText = NStr("vi = 'Ngày chứng từ không được nhỏ hơn ngày thông tin của đối tượng sửa chữa (%Date%)';
							|ru = 'Дата документа должна быть не меньше даты сведений объекта ремонта (%Date%)';
							|en = 'Document date cannot be earlier than the R&M object information record date (%Date%)'; fa = 'Document date cannot be earlier than the R&M object information record date (%Date%)';
							|it = 'Data del documento non deve essere precedente alla data di informazioni dell''oggetto di riparazione (%Date%)';
							|pl = 'Data dokumentu nie może mniejsza niż data informacji obiektu naprawy (%Date%)';
							|tr = 'Belgenin tarihi, onarım nesnesinin bilgi tarihinden az olmamalıdır (%Date%)'");
			ErrorText = StrReplace(ErrorText, "%Date%", Format(UpdateDate,"DLF=DDT"));
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				"Date",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Fills in the document based on a link to the reference list of operating objects
//
Procedure FillInDocumentBasedOnObjectOfOperation(Val Basis)
	
	DefectiveSubAssets.Clear();
	
	Query = New Query(
		"SELECT
		|	Assets.Ref AS Asset,
		|	Assets.Status AS Status,
		|	CASE
		|		WHEN Assets.Status = VALUE(Enum.AssetStatuses.InOperation)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsStatus,
		|	Assets.DeletionMark AS ThereAreErrorsRemoved,
		|	Assets.IsFolder AS ThereAreErrorsGroup
		|FROM
		|	Catalog.Assets AS Assets
		|WHERE
		|	(Assets.Ref = &Ref
		|			OR Assets.Ref IN
		|				(SELECT
		|					Nodes.Owner
		|				FROM
		|					Catalog.SubAssets AS Nodes
		|				WHERE
		|					Nodes.Ref = &Ref))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Nodes.Ref AS Node,
		|	Nodes.Status AS Status,
		|	CASE
		|		WHEN Nodes.Status = VALUE(Enum.AssetStatuses.InOperation)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsStatus,
		|	Nodes.DeletionMark AS ThereAreErrorsRemoved
		|FROM
		|	Catalog.SubAssets AS Nodes
		|WHERE
		|	CASE
		|			WHEN Nodes.Ref = &Ref
		|				THEN TRUE
		|			WHEN Nodes.Owner = &Ref
		|				THEN Nodes.Status = VALUE(Enum.AssetStatuses.InOperation)
		|						AND NOT Nodes.DeletionMark
		|			ELSE FALSE
		|		END");
	
	Query.SetParameter("Ref", Basis);
	
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
	ErrorTextStatus = NStr("vi = '%1 ""%2"" ở trạng thái ""%3"". Nhập trên cơ sở chỉ được phép trong trạng thái ""Đang sử dụng"".';
							|ru = '%1 ""%2"" находится в статусе ""%3"". Ввод на основании разрешен только в статусе ""В эксплуатации"".';
							|en = '%1 ""%2"" in ""%3"" status. To generate a document, change its status to ""Operating"".'; fa = '%1 ""%2"" in ""%3"" status. To generate a document, change its status to ""Operating"".';
							|it = '%1 ""%2"" si trova nello stato ""%3"". L''immissione in base alla causale è permessa solo nello stato ""In uso"".';
							|pl = '%1 ""%2"" ma status  ""%3"". Wprowadzenie na podstawie jest dozwolony tylko ze statusem ""W eksploatacji"".';
							|tr = '%1 ""%2"" ""%3"" durumundadır. Temelde girişe yalnızca ""İşlemde"" durumunda izin verilir.'");
	
	Package = Query.ExecuteBatch();
	If Not Package[0].IsEmpty() Then
		
		Selection = Package[0].Select();
		Selection.Next();
		
		If Selection.ThereAreErrorsGroup Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTextGroup_,
				Selection.Asset);
			Raise ErrorText;
		ElsIf Selection.ThereAreErrorsRemoved Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTextDeleted,
				NStr("vi = 'tài sản đang vận hành';
					|ru = 'Объект эксплуатации';
					|en = 'Asset'; fa = 'دارایی';
					|it = 'Oggetto di esercizio';
					|pl = 'Obiekt eksploatacji';
					|tr = 'Varlık'"),
				Selection.Asset);
			Raise ErrorText;
		ElsIf Selection.ThereAreErrorsStatus Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTextStatus,
				NStr("vi = 'tài sản đang vận hành';
					|ru = 'Объект эксплуатации';
					|en = 'Asset'; fa = 'دارایی';
					|it = 'Oggetto di esercizio';
					|pl = 'Obiekt eksploatacji';
					|tr = 'Varlık'"),
				Selection.Asset,
				Selection.Status);
			Raise ErrorText;
		EndIf;
		
		Asset = Selection.Asset;
		
	EndIf;
	
	If Not Package[1].IsEmpty() Then
		Selection = Package[1].Select();
		While Selection.Next() Do
			If Selection.ThereAreErrorsRemoved Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextDeleted,
					NStr("vi = 'Các chi tiết máy tài sản đang vận hành';
						|ru = 'Узел объекта эксплуатации';
						|en = 'Sub-asset'; fa = 'زیردارایی';
						|it = 'Nodo dell''oggetto di esercizio';
						|pl = 'Węzeł obiektu eksploatacji';
						|tr = 'Alt varlık'"),
					Selection.Node);
				Raise ErrorText;
			ElsIf Selection.ThereAreErrorsStatus Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextStatus,
					NStr("vi = 'Các chi tiết máy tài sản đang vận hành';
						|ru = 'Узел объекта эксплуатации';
						|en = 'Sub-asset'; fa = 'زیردارایی';
						|it = 'Nodo dell''oggetto di esercizio';
						|pl = 'Węzeł obiektu eksploatacji';
						|tr = 'Alt varlık'"),
					Selection.Node,
					Selection.Status);
				Raise ErrorText;
			EndIf;
			ThisObject.DefectiveSubAssets.Add().Node = Selection.Node;
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	EmployeeResponsible = Users.CurrentUser();
	
EndProcedure

#EndRegion

#EndIf
