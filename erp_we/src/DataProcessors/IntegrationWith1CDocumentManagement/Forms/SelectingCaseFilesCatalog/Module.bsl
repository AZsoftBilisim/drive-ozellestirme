#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Document = Parameters.Document;
	DocumentID = Parameters.DocumentID;
	DocumentType = Parameters.DocumentType;
	
	DocumentKind = Parameters.DocumentKind;
	DocumentKindID = Parameters.DocumentKindID;
	DocumentKindType = Parameters.DocumentKindType;
	
	QuestionOfActivity = Parameters.QuestionOfActivity;
	QuestionOfActivityID = Parameters.QuestionOfActivityID;
	QuestionOfActivityType = Parameters.QuestionOfActivityType;
	
	Counterparty = Parameters.Counterparty;
	CounterpartyID = Parameters.CounterpartyID;
	CounterpartyType = Parameters.CounterpartyType;
	
	Organization = Parameters.Organization;
	OrganizationID = Parameters.OrganizationID;
	OrganizationType = Parameters.OrganizationType;
	
	Department = Parameters.Department;
	DepartmentID = Parameters.DepartmentID;
	DepartmentType = Parameters.DepartmentType;
	
	CaseFileNomenclature = Parameters.CaseFileNomenclature;
	CaseFileNomenclatureID = Parameters.CaseFileNomenclatureID;
	CaseFileNomenclatureType = Parameters.CaseFileNomenclatureType;
	CaseFileNomenclatureYear = Parameters.CaseFileNomenclatureYear;
	
	If CaseFileNomenclatureYear = 0 Then
		CaseFileNomenclatureYear = Year(CurrentSessionDate());
	EndIf;
	
	UpdateData1();
	
	Items.List.RowFilter = New FixedStructure(
		New Structure("SectionID, SectionType", "NoSection", "NoSection"));
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShowCasesForOnChange(Item)
	
	UpdateData1();
	
	For Each String In Sections.GetItems() Do
		Items.Sections.Expand(String.GetID());
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSections

&AtClient
Procedure SectionsOnActivateRow(Item)
	
	AttachIdleHandler("IdleHandler", 0.2, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	String = Item.CurrentData;
	If String = Undefined Then
		Return;
	EndIf;
	
	CurrentCaseFileNomenclature = String.Presentation;
	CurrentCaseFileNomenclatureID = String.ID;
	CurrentCaseFileNomenclatureType = String.Type;
	CurrentCaseFileNomenclatureYear = String.Year;
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	Select();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectCommand(Command)
	
	Select();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure IdleHandler()
	
	String = Items.Sections.CurrentData;
	If String = Undefined Then
		Return;
	EndIf;
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("SectionID", ?(ValueIsFilled(String.ID), String.ID, "NoSection"));
	TheStructureOfTheSearch.Insert("SectionType", ?(ValueIsFilled(String.Type), String.Type, "NoSection"));
	Items.List.RowFilter = New FixedStructure(TheStructureOfTheSearch);
	
EndProcedure

&AtClient
Procedure Select()
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("CaseFileNomenclature", CurrentCaseFileNomenclature);
	Result.Insert("CaseFileNomenclatureID", CurrentCaseFileNomenclatureID);
	Result.Insert("CaseFileNomenclatureType", CurrentCaseFileNomenclatureType);
	Result.Insert("CaseFileNomenclatureYear", CurrentCaseFileNomenclatureYear);
	
	Close(Result);
	
EndProcedure

&AtServer
Procedure UpdateData1()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	ReadPartitionTreeIntoForm(Proxy);
	ReadListOfProductsInForm(Proxy);
	
EndProcedure

&AtServer
Procedure ReadPartitionTreeIntoForm(Proxy)
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetCaseFilesListSectionsTreeRequest");
	Query.year = CaseFileNomenclatureYear;
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
	ResultPartitionTree = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, ResultPartitionTree);
	
	SectionsTree = FormAttributeToValue("Sections");
	SectionsTree.Rows.Clear();
	
	Root = SectionsTree.Rows.Add();
	Root.Description = NStr("vi = 'Phân hệ';
							|ru = 'Разделы';
							|en = 'Sections'; fa = 'بخش‌ها';
							|it = 'Sezioni';
							|pl = 'Sections';
							|tr = 'Bölümler'");
	Root.PictureIndex = -1;
	
	FillSectionsTree(Root, ResultPartitionTree.caseFilesListSectionsTree);
	
	ValueToFormAttribute(SectionsTree, "Sections");
	
EndProcedure

&AtServer
Procedure ReadListOfProductsInForm(Proxy)
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetCaseFilesCatalogRequest");
	
	Query.year = CaseFileNomenclatureYear;
	
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
	
	ResultListOfCaseProducts = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, ResultListOfCaseProducts);
	
	Table = FormAttributeToValue("List");
	
	Table.Clear();
	For Each caseFilesCatalog In ResultListOfCaseProducts.caseFilesCatalogs Do
		NwRw = Table.Add();
		NwRw.Description = caseFilesCatalog.name;
		NwRw.Presentation = caseFilesCatalog.objectID.presentation;
		NwRw.IndexOf = caseFilesCatalog.index;
		NwRw.Year = caseFilesCatalog.year;
		NwRw.ID = caseFilesCatalog.objectID.ID;
		NwRw.Type = caseFilesCatalog.objectID.type;
		If IntegrationWith1CDocumentManagementCore.PropertySet(caseFilesCatalog, "section") Then
			NwRw.SectionID = caseFilesCatalog.section.objectID.ID;
			NwRw.SectionType = caseFilesCatalog.section.objectID.type;
		Else
			NwRw.SectionID = "NoSection";
			NwRw.SectionType = "NoSection";
		EndIf;
	EndDo;
	
	ValueToFormAttribute(Table, "List");
	
EndProcedure

&AtServer
Procedure FillSectionsTree(Tree, caseFilesListSectionsTree)
	
	For Each caseFilesListSectionsTreeElement In caseFilesListSectionsTree Do
		NewItem = Tree.Rows.Add();
		NewItem.Description = caseFilesListSectionsTreeElement.caseFilesListSection.name;
		NewItem.ID = caseFilesListSectionsTreeElement.caseFilesListSection.objectID.ID;
		NewItem.Type = caseFilesListSectionsTreeElement.caseFilesListSection.objectID.type;
		NewItem.PictureIndex = 0;
		If IntegrationWith1CDocumentManagementCore.PropertySet(
				caseFilesListSectionsTreeElement, "caseFilesListSectionsTree") Then
			FillSectionsTree(NewItem, caseFilesListSectionsTreeElement.caseFilesListSectionsTree)
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion
