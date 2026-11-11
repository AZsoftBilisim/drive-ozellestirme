#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Document = Parameters.Document;
	DocumentID = Parameters.DocumentID;
	DocumentType = Parameters.DocumentType;
	
	RegistrationDate = Parameters.RegistrationDate;
	
	DocumentKind = Parameters.DocumentKind;
	DocumentKindID = Parameters.DocumentKindID;
	DocumentKindType = Parameters.DocumentKindType;
	
	ToDoItem = Parameters.ToDoItem;
	ToDoItemID = Parameters.ToDoItemID;
	ToDoItemType = Parameters.ToDoItemType;
	
	CaseFileNomenclature = Parameters.CaseFileNomenclature;
	CaseFileNomenclatureID = Parameters.CaseFileNomenclatureID;
	CaseFileNomenclatureType = Parameters.CaseFileNomenclatureType;
	
	Counterparty = Parameters.Counterparty;
	CounterpartyID = Parameters.CounterpartyID;
	CounterpartyType = Parameters.CounterpartyType;
	
	Organization = Parameters.Organization;
	OrganizationID = Parameters.OrganizationID;
	OrganizationType = Parameters.OrganizationType;
	
	Department = Parameters.Department;
	DepartmentID = Parameters.DepartmentID;
	DepartmentType = Parameters.DepartmentType;
	
	ReadCaseTreeIntoForm();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	Select();
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	String = Item.CurrentData;
	If String = Undefined Then
		Return;
	EndIf;
	
	CurCase = String.Presentation;
	CurCaseID = String.ID;
	CurCaseType = String.Type;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectCommand(Command)
	
	Select();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ReadCaseTreeIntoForm()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetCaseFilesDossiersRequest");
	
	Query.company = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMOrganization");
	Query.company.name = Organization;
	Query.company.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		OrganizationID,
		OrganizationType);
	
	Query.department = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMSubdivision");
	Query.department.name = Department;
	Query.department.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		DepartmentID,
		DepartmentType);
	
	Query.regDate = RegistrationDate;
	
	Query.caseFilesCatalog = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMCaseFilesCatalog");
	Query.caseFilesCatalog.name = CaseFileNomenclature;
	Query.caseFilesCatalog.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		CaseFileNomenclatureID,
		CaseFileNomenclatureType);
	
	Query.documentType = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObject");
	Query.documentType.name = DocumentKind;
	Query.documentType.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		DocumentKindID,
		DocumentKindType);
	
	Query.correspondent = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMCorrespondent");
	Query.correspondent.name = Counterparty;
	Query.correspondent.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		CounterpartyID,
		CounterpartyType);
	
	Query.activityMatter = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMActivityMatter");
	Query.activityMatter.name = QuestionOfActivity;
	Query.activityMatter.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		QuestionOfActivityID,
		QuestionOfActivityType);
	
	ResultToDoList = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, ResultToDoList);
	
	FillInToDoList(ResultToDoList.caseFilesDossiers);
	
EndProcedure

&AtServer
Procedure FillInToDoList(caseFilesDossiers)
	
	UserTasksTree = FormAttributeToValue("List");
	UserTasksTree.Rows.Clear();
	
	CaseTable = New ValueTable;
	CaseTable.Columns.Add("name", New TypeDescription("String"));
	CaseTable.Columns.Add("presentation", New TypeDescription("String"));
	CaseTable.Columns.Add("ID", New TypeDescription("String"));
	CaseTable.Columns.Add("type", New TypeDescription("String"));
	CaseTable.Columns.Add("index", New TypeDescription("String"));
	CaseTable.Columns.Add("startDate", New TypeDescription("Date"));
	CaseTable.Columns.Add("endDate", New TypeDescription("Date"));
	CaseTable.Columns.Add("comment", New TypeDescription("String"));
	CaseTable.Columns.Add("year", New TypeDescription("Number"));
	CaseTable.Columns.Add("section", New TypeDescription("String"));
	For Each CaseOfDocumentStorage In caseFilesDossiers Do
		NewRow = CaseTable.Add();
		FillPropertyValues(NewRow, CaseOfDocumentStorage);
		NewRow.ID = CaseOfDocumentStorage.objectID.ID;
		NewRow.type = CaseOfDocumentStorage.objectID.type;
		NewRow.presentation = CaseOfDocumentStorage.objectID.presentation;
		NewRow.year = CaseOfDocumentStorage.caseFilesCatalog.year;
		NewRow.index = CaseOfDocumentStorage.caseFilesCatalog.index;
		If IntegrationWith1CDocumentManagementCore.PropertySet(CaseOfDocumentStorage.caseFilesCatalog, "section") Then
			NewRow.section = CaseOfDocumentStorage.caseFilesCatalog.section.name;
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	CaseFilesDossiers.name AS Description,
		|	CaseFilesDossiers.presentation AS Presentation,
		|	CaseFilesDossiers.ID AS ID,
		|	CaseFilesDossiers.type AS Type,
		|	CaseFilesDossiers.index AS IndexOf,
		|	CaseFilesDossiers.startDate AS Started_,
		|	CaseFilesDossiers.endDate AS Finished,
		|	CaseFilesDossiers.comment AS Comment,
		|	CaseFilesDossiers.year AS Year,
		|	CaseFilesDossiers.section AS Section
		|INTO DocumentStorageCases
		|FROM
		|	&CaseFilesDossiers AS CaseFilesDossiers
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentStorageCases.Year AS Year,
		|	CAST(DocumentStorageCases.Section AS STRING(1000)) AS Section,
		|	CAST(DocumentStorageCases.Description AS STRING(1000)) AS Description,
		|	DocumentStorageCases.Presentation AS Presentation,
		|	DocumentStorageCases.ID AS ID,
		|	DocumentStorageCases.Type AS Type,
		|	DocumentStorageCases.IndexOf AS IndexOf,
		|	DocumentStorageCases.Started_ AS Started_,
		|	DocumentStorageCases.Finished AS Finished,
		|	DocumentStorageCases.Comment AS Comment
		|FROM
		|	DocumentStorageCases AS DocumentStorageCases
		|
		|ORDER BY
		|	Year,
		|	Section,
		|	Description
		|TOTALS BY
		|	Year,
		|	Section";
	Query.SetParameter("CaseFilesDossiers", CaseTable);
	
	SampleYear = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SampleYear.Next() Do
		YearString = UserTasksTree.Rows.Add();
		YearString.Description = SampleYear.Year;
		YearString.PictureIndex = 2;
		
		SectionSelection = SampleYear.Select(QueryResultIteration.ByGroups);
		While SectionSelection.Next() Do
			RowSection = YearString.Rows.Add();
			RowSection.Description = SectionSelection.Section;
			RowSection.PictureIndex = 2;
			
			Selection = SectionSelection.Select();
			While Selection.Next() Do
				String = RowSection.Rows.Add();
				FillPropertyValues(String, Selection);
				String.PictureIndex = -1;
			EndDo;
			
		EndDo;
		
	EndDo;
	
	ValueToFormAttribute(UserTasksTree, "List");
	
EndProcedure

&AtClient
Procedure Select()
	
	ClearMessages();
	If CurCaseID = "" Then
		ShowMessageBox(,
			NStr("vi = 'Hãy chọn phần tử, không phải nhóm.
						|Để mở nhóm, hãy sử dụng ""Ctrl"" và mũi tên lên/xuống
						|hoặc phím ""+"" và ""-"" trên bàn phím.';
						|ru = 'Выберите элемент, а не группу.
						|Для раскрытия групп используйте ""Ctrl"" и стрелки вниз/вверх
						|или клавиши ""+"" и ""-"" на дополнительной клавиатуре.';
						|en = 'Select an item, not a group.
						|To expand groups, use ""Ctrl"" and the up/down arrows
						|or ""+"" and ""-"" keys on the additional keyboard.'; fa = 'Select an item, not a group.
						|To expand groups, use ""Ctrl"" and the up/down arrows
						|or ""+"" and ""-"" keys on the additional keyboard.';
						|it = 'Selezionare elemento, non un gruppo.
						|Per rivelare i gruppi utilizzare ""Ctrl"" e le frecce su/giù
						|o le chiavi ""+"" e ""-"" sulla tastiera aggiuntiva.';
						|pl = 'Wybierz element, a nie grupę.
						|W celu otwarcia grupy używaj ""Ctrl"" i strzałki do dołu/do góry
						|lub klawisze ""+"" i ""-"" na dodatkowej klawiaturze.';
						|tr = 'Grup değil, öğe seç.
						|Grupları genişletmek için ek klavyedeki ""Ctrl"" ve yukarı/aşağı okları
						|veya ""+"" ve ""-"" tuşlarını kullan.'"));
		Return;
	EndIf;
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("ToDoItem", CurCase);
	Result.Insert("ToDoItemID", CurCaseID);
	Result.Insert("ToDoItemType", CurCaseType);
	
	Close(Result);
	
EndProcedure

#EndRegion
