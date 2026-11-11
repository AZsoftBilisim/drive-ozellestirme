#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Tree = FormAttributeToValue("MetadataTree");
	MetadataNames = New Array;
	Types = IntegrationWith1CDocumentManagementCoreCached.TypesOfObjectsThatSupportIntegration();
	For Each Type In Types Do
		MetadataObject = Metadata.FindByType(Type);
		MetadataNames.Add(MetadataObject.FullName());
	EndDo;
	
	FillInMetadataTreeBranch(
		Tree,
		MetadataNames,
		"Catalogs",
		PictureLib.Catalog,
		NStr("vi = 'Danh mục';
			|ru = 'Справочники';
			|en = 'Catalogs'; fa = 'فهرست‌ها';
			|it = 'Directory';
			|pl = 'Kartoteki';
			|tr = 'Kataloglar'"));
	FillInMetadataTreeBranch(
		Tree,
		MetadataNames,
		"Documents",
		PictureLib.Document,
		NStr("vi = 'Chứng từ';
			|ru = 'Документы';
			|en = 'Documents'; fa = 'اسناد';
			|it = 'Documenti';
			|pl = 'Documents';
			|tr = 'Belgeler'"));
	FillInMetadataTreeBranch(
		Tree,
		MetadataNames,
		"ChartsOfCharacteristicTypes",
		PictureLib.ChartOfCharacteristicTypes,
		NStr("vi = 'Hệ thống dạng đặc tính';
			|ru = 'Планы видов характеристик';
			|en = 'Charts of characteristic types'; fa = 'Charts of characteristic types';
			|it = 'Piani dei tipi di caratteristiche';
			|pl = 'Plany rodzajów charakterystyk';
			|tr = 'Özellik türü listeleri'"));
	FillInMetadataTreeBranch(
		Tree,
		MetadataNames,
		"ChartsOfCalculationTypes",
		PictureLib.ChartOfCalculationTypes,
		NStr("vi = 'Hệ thống dạng tính toán';
			|ru = 'Планы видов расчета';
			|en = 'Charts of calculation types'; fa = 'Charts of calculation types';
			|it = 'Piani dei tipi di calcolo';
			|pl = 'Plany rodzajów obliczeń';
			|tr = 'Hesaplama türü planları'"));
	FillInMetadataTreeBranch(
		Tree,
		MetadataNames,
		"BusinessProcesses",
		PictureLib.BusinessProcess,
		NStr("vi = 'Quy trình nghiệp vụ';
			|ru = 'Бизнес-процессы';
			|en = 'Business processes'; fa = 'فرایندهای تجاری';
			|it = 'Processi aziendali';
			|pl = 'Business processes';
			|tr = 'İş süreçleri'"));
	FillInMetadataTreeBranch(
		Tree,
		MetadataNames,
		"Tasks",
		PictureLib.Task,
		NStr("vi = 'Nhiệm vụ';
			|ru = 'Задачи';
			|en = 'Tasks'; fa = 'وظایف';
			|it = 'Compiti';
			|pl = 'Tasks';
			|tr = 'Görevler'"));
	
	ValueToFormAttribute(Tree, "MetadataTree");
	
	If ValueIsFilled(Parameters.CurrentRow) Then
		For Each GroupString In MetadataTree.GetItems() Do
			For Each String In GroupString.GetItems() Do
				If String.Name = Parameters.CurrentRow Then
					Items.MetadataTree.CurrentRow = String.GetID();
					Break;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Rows = MetadataTree.GetItems();
	For Each String In Rows Do
		Items.MetadataTree.Expand(String.GetID(), True);
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMetadataTree

&AtClient
Procedure MetadataTreeValueChoice(Item, Value, StandardProcessing)
	
	ProcessTreeElementSelection();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	ProcessTreeElementSelection();
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure FillInMetadataTreeBranch(Tree, MetadataNames, Manager, Picture, Presentation)
	
	If Metadata[Manager].Count() > 0 Then
		GroupString = Tree.Rows.Add();
		GroupString.Name = "";
		GroupString.Synonym = Presentation;
		GroupString.Picture = Picture;
		For Each Object In Metadata[Manager] Do
			If MetadataNames.Find(Object.FullName()) = Undefined Then
				Continue;
			EndIf;
			NewRow = GroupString.Rows.Add();
			NewRow.Name = Object.FullName();
			NewRow.Synonym = ?(Object.Synonym = "", Object.Name, Object.Synonym);
			NewRow.Picture = GroupString.Picture;
		EndDo;
		If GroupString.Rows.Count() = 0 Then
			Tree.Rows.Delete(GroupString);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessTreeElementSelection()
	
	CurrentData = Items.MetadataTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Name = "" Then
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Name", CurrentData.Name);
	Result.Insert("Synonym", CurrentData.Synonym);
	
	Close(Result);
	
EndProcedure

#EndRegion