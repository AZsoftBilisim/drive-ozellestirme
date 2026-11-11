#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var CurContainer;
Var CurFlowOfLinkReplacement;
Var CurHandlers;
Var CurNameOfSourceLinkColumn; // See SourceLinkColumnName_

#EndRegion

#Region Internal

Procedure Initialize(Container, LinkReplacementFlow, Handlers) Export
	
	CurContainer = Container;
	CurFlowOfLinkReplacement = LinkReplacementFlow;
	CurHandlers = Handlers;
	
	FileName = Container.GetCustomFile(ExportImportDataInternal.DataTypeForColumnNameOfValueTable());
	CurNameOfSourceLinkColumn = ExportImportData.ReadObjectFromFile(FileName);
	DeleteFiles(FileName);
	
	If CurNameOfSourceLinkColumn = Undefined Or IsBlankString(CurNameOfSourceLinkColumn) Then 
		Raise NStr("vi = 'Không tìm thấy tên cột có tham chiếu gốc';
					|ru = 'Не найдено имя колонки с исходной ссылкой';
					|en = 'Name of column with source URL is not found'; fa = 'Name of column with source URL is not found';
					|it = 'Nessun nome di colonna trovato con il link di origine';
					|pl = 'Nie znaleziono nazwy kolumny z odnośnikiem źródłowym';
					|tr = 'Kaynak bağlantısı olan sütun ismi bulunamadı'");
	EndIf;
	
EndProcedure

Procedure PerformLinkMatching() Export
	
	FileDescriptionTable = CurContainer.GetFileDescriptionsFromFolder(ExportImportDataInternal.ReferenceMapping());
	
	Count_ = DataProcessors.ExportImportDataReferenceMapDictionariesDependencyGraph.Create();
	
	For Each FileDetails In FileDescriptionTable Do
		Count_.AddVertex(FileDetails.DataType);
	EndDo;
	
	TypeDependencies = ExportImportDataInternalEvents.GetTypeDependenciesWhenReplacingReferences();
	
	For Each TypeDependency In TypeDependencies Do
		
		If FileDescriptionTable.FindRows(New Structure("DataType", TypeDependency.Key)).Count() > 0 Then
			
			NamesOfDependentObjects = TypeDependency.Value; // Array of String
			For Each FullNameOfDependentObject In NamesOfDependentObjects Do
				
				If FileDescriptionTable.FindRows(New Structure("DataType", FullNameOfDependentObject)).Count() > 0 Then
					
					Count_.AddEdge(TypeDependency.Key, FullNameOfDependentObject);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	TabIndex = Count_.TopologicalSorting();
	
	For Each MetadataObject In TabIndex Do
		
		FilterParameters = New Structure();
		FilterParameters.Insert("DataType", MetadataObject.FullName());
		ReferenceMatchingDictionaries = FileDescriptionTable.FindRows(FilterParameters);
		
		For Each FileDetails In ReferenceMatchingDictionaries Do
			
			CurContainer.UnzipFile(FileDetails);
			
			// Before reading, we replace the links in the table with the values of the fields of the natural key.
			CurFlowOfLinkReplacement.ReplaceLinksInFile(FileDetails);
			
			// We read the table with the values of the fields of the natural key
			SourceRefsTable = ExportImportData.ReadObjectFromFile(FileDetails.FullName); // ValueTable
			
			DeleteFiles(FileDetails.FullName);
		
			Cancel = False;
			StandardProcessing = True;
			LinkMatchingHandler = Undefined;
			
			CurHandlers.BeforeMapRefs(
				CurContainer,
				MetadataObject,
				SourceRefsTable,
				StandardProcessing, 
				LinkMatchingHandler, 
				Cancel);
			
			If Cancel Then
				Continue;
			EndIf;
			
			If StandardProcessing Then
				
				DataProcessors.ExportImportDataReferenceMappingManager.PerformStandardLinkMatching(
					CurFlowOfLinkReplacement, MetadataObject, SourceRefsTable, ThisObject);
				
			Else
				
				XMLTypeName1 = ExportImportDataInternal.XMLRefType(MetadataObject);
				
				RefsMap = LinkMatchingHandler.MapRefs(
					CurContainer, ThisObject, SourceRefsTable); // See ExportImportPredefinedData.MapRefs
				For Each MapItem In RefsMap Do
					
					CurFlowOfLinkReplacement.ReplaceRef(XMLTypeName1, String(MapItem[CurNameOfSourceLinkColumn].UUID()),
						String(MapItem.Ref.UUID()));
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Name of the source link column
// 
// Returns:
//  String
Function SourceLinkColumnName_() Export
	
	Return CurNameOfSourceLinkColumn;
	
EndFunction

#EndRegion

#EndIf
