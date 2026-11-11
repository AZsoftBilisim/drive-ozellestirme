///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ObjectReadingAllowed(Object)";
	
	Restriction.ByOwnerWithoutSavingAccessKeys = True;
	
EndProcedure

// End StandardSubsystems.AccessManagement

// CloudTechnology.ExportImportData

// Attached in ExportImportDataOverridable.OnRegisterDataExportHandlers.
//
// Parameters:
//   Container - DataProcessorObject.ExportImportDataContainerManager
//   ObjectExportManager - DataProcessorObject.ExportImportDataInfobaseDataExportManager
//   Serializer - XDTOSerializer
//   Object - ConstantValueManager
//          - CatalogObject
//          - DocumentObject
//          - BusinessProcessObject
//          - TaskObject
//          - ChartOfAccountsObject
//          - ExchangePlanObject
//          - ChartOfCharacteristicTypesObject
//          - ChartOfCalculationTypesObject
//          - InformationRegisterRecordSet
//          - AccumulationRegisterRecordSet
//          - AccountingRegisterRecordSet
//          - CalculationRegisterRecordSet
//          - SequenceRecordSet
//          - RecalculationRecordSet
//   Artifacts - Array of XDTODataObject
//   Cancel - Boolean
//
Procedure BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel) Export
	
	TypesToExport = New Map;
	
	For Each Record In Object Do
		If Record.VersionAuthor = Undefined Then
			Continue;
		EndIf;
		
		Type = TypeOf(Record.VersionAuthor);
		ToExport = TypesToExport[Type];
		If ToExport = Undefined Then
			ToExport = Not Common.IsExchangePlan(Record.VersionAuthor.Metadata());
			TypesToExport.Insert(Type, ToExport);
		EndIf;
		
		If Not ToExport Then
			Record.VersionAuthor = Undefined;
		EndIf;
	EndDo;
	
EndProcedure

// End CloudTechnology.ExportImportData

#EndRegion

#EndRegion

#Region Private

Procedure DeleteVersionAuthorInfo(Val VersionAuthor) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "SELECT TOP 10000
	|	*
	|FROM
	|	InformationRegister.ObjectsVersions AS ObjectsVersions
	|WHERE
	|	ObjectsVersions.VersionAuthor = &VersionAuthor";
	
	Query.SetParameter("VersionAuthor", VersionAuthor);
	Selection = Query.Execute().Select();
	
	While Selection.Count() > 0 Do
		While Selection.Next() Do
			RecordSet = CreateRecordSet();
			RecordSet.Filter["Object"].Set(Selection["Object"]);
			RecordSet.Filter["VersionNumber"].Set(Selection["VersionNumber"]);
			
			Record = RecordSet.Add();
			FillPropertyValues(Record, Selection);
			Record.VersionAuthor = Undefined;
			RecordSet.Write();
		EndDo;
		
		If TransactionActive() Then
			Break;
		EndIf;
		
		Selection = Query.Execute().Select(); // @skip-check query-in-loop - Batch processing of a large amount of data.
	EndDo;
	
EndProcedure


Procedure GenerateReportOnChanges(ReportParameters, ResultAddress) Export
	// Stores the intermediate parsed version (to reduce the number of parsing runs).
	// 
	Var ObjectVersion;
	
	// Global ID used for string changes between versions.
	Var counterUniqueID;
	
	ObjectReference = ReportParameters.ObjectReference;
	VersionsList = ReportParameters.VersionsList;
	
	CommonTemplate = GetTemplate("StandardObjectPresentationTemplate");
	ReportTS = New SpreadsheetDocument;
	
	// Generate an ascending sorted array of version numbers
	// (since some versions might be missing and unsorted).
	VersionNumberArray = VersionsList.UnloadValues();
	
	// The number (k) of object versions stored in the infobase.
	// Report generation requires (k – 1) comparisons.
	// Therefore, the dimension tables will have (k) columns.
	ObjectVersionCount = VersionNumberArray.Count();
	
	// Contains all attribute changes and has the following dimensions:
	// - One dimension (rows) with the descriptions of the object attributes.
	// - Another dimension (columns) contains the object version identification and the change characteristics.
	// Here, "version identification" means the string that uniquely differentiates a version among
	// all object versions and contains additional change details.
	ChangesTableBankingDetails_ = New ValueTable;
	PrepareAttributeChangeTableColumns(ChangesTableBankingDetails_, VersionNumberArray);
	
	// Stores table changes as a map between the object's value table names and table value history.
	// One map is one table:
	// - One table (rows) contains table field descriptions.
	// - Another table (columns) contains the object version identification.
	// Here, "version identification" means the string that uniquely differentiates a version among
	// all object versions and contains additional change details.
	// 
	TabularSectionChangeTable = New Map;
	
	SpreadsheetDocuments = New ValueList;
	SpreadsheetDocumentChangeTable = New ValueTable;
	SpreadsheetDocumentChangeTable.Columns.Add("Description");
	SpreadsheetDocumentChangeTable.Columns.Add("Presentation");
	//
	
	// Generate the object's initial versions that are always shown
	// (in case there are follow-up changes).
	ObjectVersionPrev = CountInitialAttributeAndTabularSectionValues(ChangesTableBankingDetails_, TabularSectionChangeTable,
		ObjectVersionCount, VersionNumberArray, ObjectReference);
	
	SpreadsheetDocuments.Add(ObjectVersionPrev.SpreadsheetDocuments);
	SpreadsheetDocumentChangeTable.Columns.Add("Version" + Format(VersionNumberArray[0], "NG=0"));
	
	counterUniqueID = GetUUID(TabularSectionChangeTable, "Version" + Format(VersionNumberArray[0], "NG=0"));
	
	For VersionIndex = 2 To VersionNumberArray.Count() Do
		VersionNumber = VersionNumberArray[VersionIndex-1];
		PreviousVersionNumber = "Version" + (Format(VersionNumberArray[VersionIndex-2], "NG=0"));
		CurrentVersionColumnName = "Version" + Format(VersionNumber, "NG=0");
		
		ComparisonResult = CalculateChanges(VersionNumber, ObjectVersionPrev, ObjectVersion, ObjectReference);
		
		SpreadsheetDocuments.Add(ObjectVersion.SpreadsheetDocuments);
		
		// Filling the attribute report table.
		FillAttributeChangingCharacteristic(ComparisonResult["Attributes"]["And"],
			"And", ChangesTableBankingDetails_, CurrentVersionColumnName, ObjectVersion);
		FillAttributeChangingCharacteristic(ComparisonResult["Attributes"]["d"],
			"D", ChangesTableBankingDetails_, CurrentVersionColumnName, ObjectVersion);
		FillAttributeChangingCharacteristic(ComparisonResult["Attributes"]["u"],
			"U", ChangesTableBankingDetails_, CurrentVersionColumnName, ObjectVersion);
		
		// Changes in tabular sections.
		TabularSectionChanges1 = ComparisonResult["TabularSections"]["And"];
		
		For Each MapItem In ObjectVersion.TabularSections Do
			TableName = MapItem.Key;
			
			If TabularSectionChangeTable[TableName] = Undefined Then
				Continue;
			EndIf;
			
			TabularSectionChangeTable[TableName][CurrentVersionColumnName] = 
				ObjectVersion.TabularSections[TableName].Copy();
				
			TableVersionRef = TabularSectionChangeTable[TableName][CurrentVersionColumnName];// ValueTable
			TableVersionRef.Columns.Add(NameOfLineIDColumn());
			For Each TableRow In TableVersionRef Do
				TableRow[NameOfLineIDColumn()] = TableRow.LineNumber;
			EndDo;
			
			TableVersionRef.Columns.Add(NameOfModificationColumn());
			TableVersionRef.FillValues(False, NameOfModificationColumn());
			
			TableVersionRef.Columns.Add(NameOfChangesColumn(), New TypeDescription("Array"));
			
			TableWithChanges = TabularSectionChanges1.Get(TableName);
			If TableWithChanges <> Undefined Then
				ModifiedRows = TableWithChanges["And"];
				AddedRows = TableWithChanges["D"];
				DeletedRows = TableWithChanges["U"];
				
				For Each TSItem In ModifiedRows Do
					VCTRow = TabularSectionChangeTable[TableName][PreviousVersionNumber][TSItem.IndexInTS0-1];
					TableVersionRef[TSItem.IndexInTS1-1][NameOfLineIDColumn()] = VCTRow[NameOfLineIDColumn()];
					TableVersionRef[TSItem.IndexInTS1-1][NameOfModificationColumn()] = "And";
					TableVersionRef[TSItem.IndexInTS1-1][NameOfChangesColumn()] = TSItem.Differences1;
				EndDo;
				
				For Each TSItem In AddedRows Do
					TableVersionRef[TSItem.IndexInTS1-1][NameOfLineIDColumn()] = IncreaseCounter(counterUniqueID, TableName);
					TableVersionRef[TSItem.IndexInTS1-1][NameOfModificationColumn()] = "D";
				EndDo;
				
				// UniqueID must be assigned for each item, for comparison with previous versions.
				For IndexOf = 1 To TableVersionRef.Count() Do
					If TableVersionRef[IndexOf-1][NameOfLineIDColumn()] = Undefined Then
						// Found a row that must be looked up for mapping in the previous table.
						TSRow = TableVersionRef[IndexOf-1];
						
						FilterParameters = New Structure;
						CommonColumns = FindCommonColumns(TableVersionRef, TabularSectionChangeTable[TableName][PreviousVersionNumber]);
						For Each ColumnName In CommonColumns Do
							If (ColumnName <> NameOfLineIDColumn()) And (ColumnName <> NameOfModificationColumn()) Then
								FilterParameters.Insert(ColumnName, TSRow[ColumnName]);
							EndIf;
						EndDo;
						
						PreviousTSRowArray = TabularSectionChangeTable[TableName][PreviousVersionNumber].FindRows(FilterParameters);
						
						FilterParameters.Insert(NameOfModificationColumn(), Undefined);
						CurrentTSRowArray = TableVersionRef.FindRows(FilterParameters);
						
						For IDByTSCurrent = 1 To CurrentTSRowArray.Count() Do
							If IDByTSCurrent <= PreviousTSRowArray.Count() Then
								CurrentTSRowArray[IDByTSCurrent-1][NameOfLineIDColumn()] = PreviousTSRowArray[IDByTSCurrent-1][NameOfLineIDColumn()];
							EndIf;
							CurrentTSRowArray[IDByTSCurrent-1][NameOfModificationColumn()] = False;
						EndDo;
					EndIf;
				EndDo;
				For Each TSItem In DeletedRows Do
					RowImaginary = TableVersionRef.Add();
					RowImaginary[NameOfLineIDColumn()] = TabularSectionChangeTable[TableName][PreviousVersionNumber][TSItem.IndexInTS0-1][NameOfLineIDColumn()];
					RowImaginary[NameOfModificationColumn()] = "U";
				EndDo;
			EndIf;
		EndDo;
		
		SpreadsheetDocumentChangeTable.Columns.Add(CurrentVersionColumnName);
		
		ResultTable  = ComparisonResult["SpreadsheetDocuments"]["And"];
		For Each CurRow In ResultTable Do
			ChangeTableRow = SpreadsheetDocumentChangeTable.Find(CurRow.Value, "Description");
			If ChangeTableRow = Undefined Then
				ChangeTableRow = SpreadsheetDocumentChangeTable.Add();
				ChangeTableRow.Description = CurRow.Value;
				ChangeTableRow.Presentation = CurRow.Presentation;
			EndIf;
			ChangeTableRow[CurrentVersionColumnName] = "And";
		EndDo;
		
		ResultTable  = ComparisonResult["SpreadsheetDocuments"]["d"];
		For Each CurRow In ResultTable Do
			ChangeTableRow = SpreadsheetDocumentChangeTable.Find(CurRow.Value, "Description");
			If ChangeTableRow = Undefined Then
				ChangeTableRow = SpreadsheetDocumentChangeTable.Add();
				ChangeTableRow.Description = CurRow.Value;
				ChangeTableRow.Presentation = CurRow.Presentation;
			EndIf;
			ChangeTableRow[CurrentVersionColumnName] = "D";
		EndDo;
		
		ResultTable  = ComparisonResult["SpreadsheetDocuments"]["u"];
		For Each CurRow In ResultTable Do
			ChangeTableRow = SpreadsheetDocumentChangeTable.Find(CurRow.Value, "Description");
			If ChangeTableRow = Undefined Then
				ChangeTableRow = SpreadsheetDocumentChangeTable.Add();
				ChangeTableRow.Description = CurRow.Value;
				ChangeTableRow.Presentation = CurRow.Presentation;
			EndIf;
			ChangeTableRow[CurrentVersionColumnName] = "U";
		EndDo;
		
		ObjectVersionPrev = ObjectVersion;
	EndDo;
	
	Parameters = New Structure;
	Parameters.Insert("ChangesTableBankingDetails_", ChangesTableBankingDetails_);
	Parameters.Insert("TabularSectionChangeTable", TabularSectionChangeTable);
	Parameters.Insert("SpreadsheetDocumentChangeTable", SpreadsheetDocumentChangeTable);
	Parameters.Insert("counterUniqueID", counterUniqueID);
	Parameters.Insert("VersionsList", VersionsList);
	Parameters.Insert("ReportTS", ReportTS);
	Parameters.Insert("CommonTemplate", CommonTemplate);
	Parameters.Insert("ObjectReference", ObjectReference);
	OutputCompositionResultsInReportLayout(Parameters);
	
	TemplateLegend = CommonTemplate.GetArea("Legend");
	ReportTS.Put(TemplateLegend);
	
	PutToTempStorage(ReportTS, ResultAddress);
EndProcedure

Procedure OutputAttributeChanges(ReportTS, ChangesTableBankingDetails_, VersionNumberArray, CommonTemplate, ObjectReference)
	
	AttributeHeaderArea = CommonTemplate.GetArea("AttributeHeader");
	ReportTS.Put(AttributeHeaderArea);
	ReportTS.StartRowGroup("AttributeGroup");
	
	For Each ModAttributeItem In ChangesTableBankingDetails_ Do
		If ModAttributeItem[NameOfModificationColumn()] = True Then
			
			DescriptionDetailsStructure = ObjectsVersioning.DisplayedAttributeDescription(ObjectReference, ModAttributeItem.Description);
			If Not DescriptionDetailsStructure.OutputAttribute Then
				Continue;
			EndIf;
			
			DisplayedDescription = DescriptionDetailsStructure.DisplayedDescription;
			
			EmptyCell = CommonTemplate.GetArea("EmptyCell");
			ReportTS.Put(EmptyCell);
			
			AttributeDescription = CommonTemplate.GetArea("FieldAttributeDescription");
			AttributeDescription.Parameters.FieldAttributeDescription = DisplayedDescription;
			ReportTS.Join(AttributeDescription);
			
			IndexByAttributeVersions = VersionNumberArray.Count();
			
			While IndexByAttributeVersions >= 1 Do
				ChangeCharacteristicStructure = ModAttributeItem["Version" + Format(VersionNumberArray[IndexByAttributeVersions-1], "NG=0")];
				
				AttributeValuePresentation = "";
				AttributeValue = "";
				Update = Undefined;
				
				// Skipping to the next version if the attribute was not changed in the current version.
				If TypeOf(ChangeCharacteristicStructure) = Type("String") Then
					
					AttributeValuePresentation = String(AttributeValue);
					
				ElsIf ChangeCharacteristicStructure <> Undefined Then
					If ChangeCharacteristicStructure.ChangeKind = "U" Then
					Else
						AttributeValue = ChangeCharacteristicStructure.Value.AttributeValue;
						AttributeValuePresentation = String(AttributeValue);
					EndIf;
					// Getting the attribute change structure for the current version.
					Update = ChangeCharacteristicStructure.ChangeKind;
				EndIf;
				
				If AttributeValuePresentation = "" Then
					AttributeValuePresentation = AttributeValue;
					If AttributeValuePresentation = "" Then
						AttributeValuePresentation = " ";
					EndIf;
				EndIf;
				
				If      Update = Undefined Then
					AttributeValueArea = CommonTemplate.GetArea("InitialAttributeValue");
					AttributeValueArea.Parameters.AttributeValue = AttributeValuePresentation;
				ElsIf Update = "And" Then
					AttributeValueArea = CommonTemplate.GetArea("ModifiedAttributeValue");
					AttributeValueArea.Parameters.AttributeValue = AttributeValuePresentation;
				ElsIf Update = "U" Then
					AttributeValueArea = CommonTemplate.GetArea("DeletedAttribute");
					AttributeValueArea.Parameters.AttributeValue = AttributeValuePresentation;
				ElsIf Update = "D" Then
					AttributeValueArea = CommonTemplate.GetArea("AddedAttribute");
					AttributeValueArea.Parameters.AttributeValue = AttributeValuePresentation;
				EndIf;
				
				ReportTS.Join(AttributeValueArea);
				
				IndexByAttributeVersions = IndexByAttributeVersions - 1;
			EndDo;
		EndIf;
	EndDo;
	
	ReportTS.EndRowGroup();
	
EndProcedure

Procedure OutputTabularSectionChanges(ReportTS, TabularSectionChangeTable, VersionNumberArray,
	counterUniqueID, CommonTemplate, ObjectReference)
	
	TabularSectionAreaHeaderDisplayed = False;
	
	EmptyRowTemplate = CommonTemplate.GetArea("EmptyRow");
	
	ReportTS.Put(EmptyRowTemplate);
	
	// Loop through all modified items. 
	For Each ChangedTSItem In TabularSectionChangeTable Do
		TabularSectionName = ChangedTSItem.Key;
		CurrentTSVersions = ChangedTSItem.Value;
		
		ObjectMetadata = ObjectReference.Metadata();
		TabularSectionPresentation = TabularSectionName;
		TabularSectionDetails = ObjectsVersioning.TabularSectionMetadata(ObjectMetadata, TabularSectionName);
		If TabularSectionDetails <> Undefined Then
			TabularSectionPresentation = TabularSectionDetails.Presentation();
		EndIf;
		
		CurrentTabularSectionChanged = False;
		
		For CurrCounterUUID = 1 To counterUniqueID[TabularSectionName] Do
			
			UUIDStringChanged = False;
			
			// Search in all versions by the current row (UniqueID = CurrCounterUUID). 
			// If the row is deleted, highlight it with the "deleted entity" color,
			// interrupt the search, and move to the next row.
			IndexByVersions = VersionNumberArray.Count();
			
			// ---------------------------------------------------------------------------------
			// Preview the versions to make sure that they contain the changes ---
			
			RowModified = False;
			
			While IndexByVersions >= 1 Do
				CurrentTSVersionColumn = "Version" + Format(VersionNumberArray[IndexByVersions-1], "NG=0");
				CurrentVersionTS = CurrentTSVersions[CurrentTSVersionColumn];
				
				FoundRow = Undefined;
				If CurrentVersionTS.Columns.Find(NameOfLineIDColumn()) <> Undefined Then
					FoundRow = CurrentVersionTS.Find(CurrCounterUUID, NameOfLineIDColumn());
				EndIf;
				
				If FoundRow <> Undefined Then
					If (FoundRow[NameOfModificationColumn()] <> Undefined) Then
						If (TypeOf(FoundRow[NameOfModificationColumn()]) = Type("String")
							Or (TypeOf(FoundRow[NameOfModificationColumn()]) = Type("Boolean")
							      And FoundRow[NameOfModificationColumn()] = True)) Then
							RowModified = True;
						EndIf;
					EndIf;
				EndIf;
				IndexByVersions = IndexByVersions - 1;
			EndDo;
			
			If Not RowModified Then
				Continue;
			EndIf;
			
			// ---------------------------------------------------------------------------------
			
			// Displaying the versions as a spreadsheet document.
			IndexByVersions = VersionNumberArray.Count();
			
			IntervalBetweenFillings = 0;
			
			// Iterate through all versions. Find the changes in each of the versions by the row's ID.
			// 
			While IndexByVersions >= 1 Do
				IntervalBetweenFillings = IntervalBetweenFillings + 1;
				CurrentTSVersionColumn = "Version" + Format(VersionNumberArray[IndexByVersions-1], "NG=0");
				// Tabular section of the current version (table of modified values).
				CurrentVersionTS = CurrentTSVersions[CurrentTSVersionColumn];// ValueTable
				FoundRow = CurrentVersionTS.Find(CurrCounterUUID, NameOfLineIDColumn());
				
				// Changed row found in a version (this change is possibly the latest).
				If FoundRow <> Undefined Then
					
					// This section displays common header for the tabular sections area.
					If Not TabularSectionAreaHeaderDisplayed Then
						TabularSectionAreaHeaderDisplayed = True;
						CommonTSSectionHeaderTemplate = CommonTemplate.GetArea("TabularSectionsHeader");
						ReportTS.Put(CommonTSSectionHeaderTemplate);
						ReportTS.StartRowGroup("TabularSectionsGroup1");
						ReportTS.Put(EmptyRowTemplate);
					EndIf;
					
					// This section displays header for the current tabular section.
					If Not CurrentTabularSectionChanged Then
						CurrentTabularSectionChanged = True;
						CurrentTSHeaderTemplate = CommonTemplate.GetArea("TabularSectionHeader");
						CurrentTSHeaderTemplate.Parameters.TabularSectionDescription = TabularSectionPresentation;
						ReportTS.Put(CurrentTSHeaderTemplate);
						ReportTS.StartRowGroup("TabularSection"+TabularSectionName);
						ReportTS.Put(EmptyRowTemplate);
					EndIf;
					
					Modification = FoundRow[NameOfModificationColumn()];
					
					If UUIDStringChanged = False Then
						UUIDStringChanged = True;
						
						TSRowHeaderTemplate = CommonTemplate.GetArea("TabularSectionRowHeader");
						TSRowHeaderTemplate.Parameters.TabularSectionRowNumber = CurrCounterUUID;
						ReportTS.Put(TSRowHeaderTemplate);
						ReportTS.StartRowGroup("LinesGroup"+TabularSectionName+CurrCounterUUID);
						
						OutputType = "";
						If Modification = "U" Then
							OutputType = "U"
						EndIf;
						FillArray = New Array;
						For Each Column In CurrentVersionTS.Columns Do
							If StrFind(Column.Name, InternalColumnPrefix()) = 1 Then
								Continue;
							EndIf;
							AttributeRepresentation = Column.Name;
							If ValueIsFilled(Column.Title) Then
								AttributeRepresentation = Column.Title;
							Else
								If TabularSectionDetails <> Undefined Then
									AttributeDetails = ObjectsVersioning.TabularSectionAttributeMetadata(TabularSectionDetails, Column.Name);
									If AttributeDetails = Undefined And Metadata.ChartsOfAccounts.Contains(ObjectMetadata) Then
										AttributeDetails = ObjectMetadata.ExtDimensionAccountingFlags.Find(Column.Name);
									EndIf;
									If AttributeDetails <> Undefined Then
										AttributeRepresentation = AttributeDetails.Presentation();
									EndIf;
								EndIf;
							EndIf;
							FillArray.Add(AttributeRepresentation);
						EndDo;
						
						EmptySector = GenerateEmptySector(CommonTemplate, CurrentVersionTS.Columns.Count()-2);
						EmptySectorToFill = GenerateEmptySector(CommonTemplate, CurrentVersionTS.Columns.Count()-2, OutputType);
						Section3 = GenerateTSRowSector(CommonTemplate, FillArray, OutputType);
						
						ReportTS.Join(EmptySector);
						ReportTS.Join(Section3);
					EndIf;
					
					While IntervalBetweenFillings > 1 Do
						ReportTS.Join(EmptySectorToFill);
						IntervalBetweenFillings = IntervalBetweenFillings - 1;
					EndDo;
					
					IntervalBetweenFillings = 0;
					
					// Filling the next changed table row.
					FillArray = New ValueList;
					For Each Column In CurrentVersionTS.Columns Do
						If StrFind(Column.Name, InternalColumnPrefix()) = 1 Then
							Continue;
						EndIf;
						
						Presentation = String(FoundRow[Column.Name]);
						NamesOfColumnsWithChanges = FoundRow[NameOfChangesColumn()]; // Array
						FillArray.Add(NamesOfColumnsWithChanges.Find(Column.Name) <> Undefined, Presentation);
					EndDo;
					
					If TypeOf(Modification) = Type("Boolean") Then
						OutputType = "";
					Else
						OutputType = Modification;
					EndIf;
					
					Section3 = GenerateTSRowSector(CommonTemplate, FillArray, OutputType);
					ReportTS.Join(Section3);
				EndIf;
				IndexByVersions = IndexByVersions - 1;
			EndDo;
			
			If UUIDStringChanged Then
				ReportTS.EndRowGroup();
				ReportTS.Put(EmptyRowTemplate);
			EndIf;
			
		EndDo;
		
		If CurrentTabularSectionChanged Then
			ReportTS.EndRowGroup();
			ReportTS.Put(EmptyRowTemplate);
		EndIf;
		
	EndDo;
	
	If TabularSectionAreaHeaderDisplayed Then
		ReportTS.EndRowGroup();
		ReportTS.Put(EmptyRowTemplate);
	EndIf;
	
EndProcedure

Procedure OutputSpreadsheetDocumentsChanges(ReportTS, VersionNumberArray, SpreadsheetDocumentChangeTable, CommonTemplate)
	
	If SpreadsheetDocumentChangeTable.Count() = 0 Then
		Return;
	EndIf;
	
	TemplateHeaderSpreadsheetDocuments	= CommonTemplate.GetArea("SpreadsheetDocumentsHeader");
	ReportTS.Put(TemplateHeaderSpreadsheetDocuments);
	
	ReportTS.StartRowGroup("SpreadsheetDocumentsGroup1");
	
	TemplateEmptyRow	 = CommonTemplate.GetArea("EmptyRow");
	ReportTS.Put(TemplateEmptyRow);
	
	TemplateRowSpreadsheetDocuments = CommonTemplate.GetArea("SpreadsheetDocumentHeader");
	
	TemplateCellNotChanged = CommonTemplate.GetArea("SpreadsheetDocumentsIdentical");
	TemplateCellChanged = CommonTemplate.GetArea("SpreadsheetDocumentsDifferent");
	TemplateCellAdded = CommonTemplate.GetArea("SpreadsheetDocumentsAdded");
	TemplateCellDeleted = CommonTemplate.GetArea("SpreadsheetDocumentsDeleted");
		
	For Each CurRow In SpreadsheetDocumentChangeTable Do
		TemplateRowSpreadsheetDocuments.Parameters.SpreadsheetDocumentDescription = CurRow.Presentation;
		ReportTS.Put(TemplateRowSpreadsheetDocuments);
		UBound = VersionNumberArray.UBound();
		For IndexOf = 0 To UBound Do
			VersionNumberIndex = UBound-IndexOf;
			VersionNumber = VersionNumberArray[VersionNumberIndex];
			ColumnName = "Version" + Format(VersionNumber, "NG=0");
			
			If CurRow[ColumnName] = "And" Then
				Area = ReportTS.Join(TemplateCellChanged);
				VersionNumber0 = Format(VersionNumber, "NG=0");
				VersionNumber1 = Format(VersionNumberArray[VersionNumberIndex-1], "NG=0");
				TextTemplate1 = NStr("vi = 'so sánh phiên bản số %1 với phiên bản số %2';
									|ru = 'сравнить версию №%1 с версией №%2';
									|en = 'compare version #%1 with version #%2'; fa = 'compare version #%1 with version #%2';
									|it = 'Confronta la versione №%1 con la versione №%2';
									|pl = 'porównać nr%1 wersji z numerem%2 wersji';
									|tr = '%1 sayılı sürümü %2 sayılı sürüm ile karşılaştır'");
				Area.Text = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, VersionNumber0, VersionNumber1);
				Area.Details = New Structure("Compare, Version0, Version1",
					CurRow.Description, VersionNumberIndex, VersionNumberIndex-1);
				
			ElsIf CurRow[ColumnName] = "U" Then
				Area = ReportTS.Join(TemplateCellDeleted);
				Area.Text = NStr("vi = 'Đã ngắt lưu lại những thay đổi của văn bản dạng bảng';
								|ru = 'Сохранение изменений табличного документа отключено';
								|en = 'Saving changes is disabled for spreadsheet documents'; fa = 'Saving changes is disabled for spreadsheet documents';
								|it = 'Il salvataggio delle modifiche in un foglio di calcolo è disabilitato.';
								|pl = 'Zapisywanie zmian w dokumencie tabelarycznego jest wyłączone';
								|tr = 'Tablo belgesindeki değişiklikleri kaydetme devre dışı bırakıldı'");
				
			ElsIf CurRow[ColumnName] = "D" Then
				Area = ReportTS.Join(TemplateCellAdded);
				Area.Text = NStr("vi = 'mở';
								|ru = 'открыть';
								|en = 'open'; fa = 'باز';
								|it = 'aprire';
								|pl = 'open';
								|tr = 'aç'");
				Area.Details = New Structure("Open, Version", CurRow.Description, VersionNumberIndex); 
				
			Else
				Area = ReportTS.Join(TemplateCellNotChanged);
				
			EndIf;
		EndDo;
		ReportTS.Put(TemplateEmptyRow);
	EndDo;
	
	ReportTS.EndRowGroup();
	ReportTS.Put(TemplateEmptyRow);
	
EndProcedure

Procedure OutputCompositionResultsInReportLayout(Parameters)
	ChangesTableBankingDetails_ = Parameters.ChangesTableBankingDetails_;
	TabularSectionChangeTable = Parameters.TabularSectionChangeTable;
	SpreadsheetDocumentChangeTable = Parameters.SpreadsheetDocumentChangeTable;
	counterUniqueID = Parameters.counterUniqueID;
	VersionsList = Parameters.VersionsList;
	ReportTS = Parameters.ReportTS;
	CommonTemplate = Parameters.CommonTemplate;
	ObjectReference = Parameters.ObjectReference;
	
	VersionNumberArray = VersionsList.UnloadValues();
	
	ChangedAttributeCount = CalculateChangedAttributeCount(ChangesTableBankingDetails_, VersionNumberArray);
	VersionsCount = VersionNumberArray.Count();
	
	ReportTS.Clear();
	OutputHeader(ReportTS, VersionsList, VersionsCount, CommonTemplate, ObjectReference);
	
	If ChangedAttributeCount = 0 Then
		AttributeHeaderArea = CommonTemplate.GetArea("AttributeHeader");
		ReportTS.Put(AttributeHeaderArea);
		ReportTS.StartRowGroup("AttributeGroup");
		AttributesUnchangedSection = CommonTemplate.GetArea("AttributesUnchanged");
		ReportTS.Put(AttributesUnchangedSection);
		ReportTS.EndRowGroup();
	Else
		OutputAttributeChanges(ReportTS, ChangesTableBankingDetails_, VersionNumberArray, CommonTemplate, ObjectReference);
	EndIf;
	
	OutputTabularSectionChanges(ReportTS, TabularSectionChangeTable, VersionNumberArray, counterUniqueID, CommonTemplate, ObjectReference);
	OutputSpreadsheetDocumentsChanges(ReportTS, VersionNumberArray, SpreadsheetDocumentChangeTable, CommonTemplate);

	ReportTS.TotalsBelow = False;
	ReportTS.ShowGrid = False;
	ReportTS.Protection = False;
	ReportTS.ReadOnly = True;
	
EndProcedure

Procedure OutputHeader(ReportTS, VersionsList, VersionsCount, CommonTemplate, ObjectReference)
	
	SectionHeader = CommonTemplate.GetArea("Header");
	SectionHeader.Parameters.ReportDescription1 = NStr("vi = 'Báo cáo về các thay đổi phiên bản của đối tượng';
														|ru = 'Отчет по изменениям версий объекта';
														|en = 'Object version delta report'; fa = 'Object version delta report';
														|it = 'Report sulle modifiche alla versione dell''oggetto';
														|pl = 'Raport zmiany wersji obiektu';
														|tr = 'Nesne sürüm değişikliği raporu'");
	SectionHeader.Parameters.ObjectDescription = String(ObjectReference);
	
	ReportTS.Put(SectionHeader);
	
	EmptyCell = CommonTemplate.GetArea("EmptyCell");
	VersionArea = CommonTemplate.GetArea("VersionTitle");
	ReportTS.Join(EmptyCell);
	ReportTS.Join(VersionArea);
	VersionArea = CommonTemplate.GetArea("VersionPresentation");
	
	VersionComments = New Structure;
	HasComments = False;
	
	IndexByVersions = VersionsCount;
	While IndexByVersions > 0 Do
		
		VersionInfo = GetVersionDetails(ObjectReference, VersionsList[IndexByVersions-1]);
		VersionArea.Parameters.VersionPresentation = VersionInfo.LongDesc;
		
		VersionComments.Insert("Comment" + IndexByVersions, VersionInfo.Comment);
		If Not IsBlankString(VersionInfo.Comment) Then
			HasComments = True;
		EndIf;
		
		ReportTS.Join(VersionArea);
		ReportTS.Area("C" + Format(IndexByVersions + 2, "NG=0")).ColumnWidth = 50;
		IndexByVersions = IndexByVersions - 1;
		
	EndDo;
	
	If HasComments Then
		
		AreaComment = CommonTemplate.GetArea("TitleComment");
		ReportTS.Put(EmptyCell);
		ReportTS.Join(AreaComment);
		AreaComment = CommonTemplate.GetArea("Comment");
		
		IndexByVersions = VersionsCount;
		While IndexByVersions > 0 Do
			
			AreaComment.Parameters.Comment = VersionComments["Comment" + IndexByVersions];
			ReportTS.Join(AreaComment);
			IndexByVersions = IndexByVersions - 1;
			
		EndDo;
		
	EndIf;
	
	EmptyRowArea = CommonTemplate.GetArea("EmptyRow");
	ReportTS.Put(EmptyRowArea);
	
EndProcedure

Function CalculateChanges(VersionNumber, VersionParsingResult0, VersionParsingResult1, ObjectReference)
	
	// Parsing the previous version.
	Attributes_0      = VersionParsingResult0.Attributes;
	TabularSections_0 = VersionParsingResult0.TabularSections;
	
	// Parsing the latest version.
	VersionParsingResult1 = ObjectsVersioning.ParseVersion(ObjectReference, VersionNumber);
	AddRowNumbersToTabularSections(VersionParsingResult1.TabularSections);
	
	Attributes_1      = VersionParsingResult1.Attributes;
	TabularSections_1 = VersionParsingResult1.TabularSections;
	
	///////////////////////////////////////////////////////////////////////////////
	//           Generate a list of modified tables //
	///////////////////////////////////////////////////////////////////////////////
//
	TabularSectionList0	= CreateComparisonChart();
	For Each Item In TabularSections_0 Do
		NewRow = TabularSectionList0.Add();
		NewRow.Set(0, TrimAll(Item.Key));
	EndDo;
	
	TabularSectionList1	= CreateComparisonChart();
	For Each Item In TabularSections_1 Do
		NewRow = TabularSectionList1.Add();
		NewRow.Set(0, TrimAll(Item.Key));
	EndDo;
	
	// Metadata structure is possibly changed: attributes were added or deleted.
	TSToAddList = SubtractTable(TabularSectionList1, TabularSectionList0);
	DeletedTSList  = SubtractTable(TabularSectionList0, TabularSectionList1);
	
	// List of unchanged attributes that will be used to search for matches/differences.
	RemainingTSList = SubtractTable(TabularSectionList1, TSToAddList);
	
	// List of attributes that were changed.
	ChangedTSList = FindChangedTabularSections(RemainingTSList,
	                                                       TabularSections_0,
	                                                       TabularSections_1);
	
	///////////////////////////////////////////////////////////////////////////////
	//           Generate a list of modified attributes //
	///////////////////////////////////////////////////////////////////////////////
//
	AttributesList0 = CreateComparisonChart();
	For Each Attribute In VersionParsingResult0.Attributes Do
		NewRow = AttributesList0.Add();		
		NewRow.Set(0, String(Attribute.AttributeDescription));
	EndDo;
	
	AttributesList1 = CreateComparisonChart();
	For Each Attribute In VersionParsingResult1.Attributes Do
		NewRow = AttributesList1.Add();
		NewRow.Set(0, String(Attribute.AttributeDescription));
	EndDo;
	
	// Metadata structure is possibly changed: attributes were added or deleted.
	AddedAttributeList = SubtractTable(AttributesList1, AttributesList0);
	DeletedAttributeList  = SubtractTable(AttributesList0, AttributesList1);
	
	// List of unchanged attributes that will be used to search for matches/differences.
	RemainingAttributeList = SubtractTable(AttributesList1, AddedAttributeList);
	
	// List of attributes that were changed.
	ChangedAttributeList = CreateComparisonChart();
	
	ChangesInAttributes = New Map;
	ChangesInAttributes.Insert("d", AddedAttributeList);
	ChangesInAttributes.Insert("u", DeletedAttributeList);
	ChangesInAttributes.Insert("And", ChangedAttributeList);
	
	For Each ValueTableRow In RemainingAttributeList Do
		
		Attribute = ValueTableRow.Value;
		Value_0 = Attributes_0.Find(Attribute, "AttributeDescription").AttributeValue;
		Value_1 = Attributes_1.Find(Attribute, "AttributeDescription").AttributeValue;
		
		If TypeOf(Value_0) <> Type("ValueStorage")
			And TypeOf(Value_1) <> Type("ValueStorage") Then
			If Value_0 <> Value_1 Then
				NewRow = ChangedAttributeList.Add();
				NewRow.Set(0, Attribute);
			EndIf;
		EndIf;
		
	EndDo;
	
	ChangesInTables = CalculateChangesInTabularSections(
	                              ChangedTSList,
	                              TabularSections_0,
	                              TabularSections_1);
	
	///////////////////////////////////////////////////////////////////////////////
	//                      Generate a list of "SpreadsheetDocument" //
	///////////////////////////////////////////////////////////////////////////////
//
	
	SpreadsheetDocuments0 = VersionParsingResult0.SpreadsheetDocuments;// See ObjectsVersioning.ObjectSpreadsheetDocuments
	SpreadsheetDocuments1 = VersionParsingResult1.SpreadsheetDocuments;// See ObjectsVersioning.ObjectSpreadsheetDocuments
	
	SpreadsheetDocumentsList0 = CreateComparisonChart();
	SpreadsheetDocumentsList0.Columns.Add("Presentation");
	If SpreadsheetDocuments0 <> Undefined Then
		For Each StructureItem In SpreadsheetDocuments0 Do
			NewRow = SpreadsheetDocumentsList0.Add();
			NewRow.Value = StructureItem.Key;
			NewRow.Presentation = StructureItem.Value.Description;
		EndDo;
	EndIf;
	
	SpreadsheetDocumentsList1 = CreateComparisonChart();
	SpreadsheetDocumentsList1.Columns.Add("Presentation");
	If SpreadsheetDocuments1 <> Undefined Then
		For Each StructureItem In SpreadsheetDocuments1 Do
			NewRow = SpreadsheetDocumentsList1.Add();
			NewRow.Value = StructureItem.Key;
			NewRow.Presentation = StructureItem.Value.Description;
		EndDo;
	EndIf;
	
	AddedSpreadsheetDocumentsList	= SubtractTable(SpreadsheetDocumentsList1, SpreadsheetDocumentsList0);
	DeletedSpreadsheetDocumentsList		= SubtractTable(SpreadsheetDocumentsList0, SpreadsheetDocumentsList1);
	RemainingSpreadsheetDocumentsList		= SubtractTable(SpreadsheetDocumentsList1, 
													AddedSpreadsheetDocumentsList);
	
	ModifiedSpreadsheetDocumentsList	= CreateComparisonChart();
	ModifiedSpreadsheetDocumentsList.Columns.Add("Presentation");
	
	ChangesInSpreadsheetDocuments = New Map;
	ChangesInSpreadsheetDocuments.Insert("d", AddedSpreadsheetDocumentsList);
	ChangesInSpreadsheetDocuments.Insert("u", DeletedSpreadsheetDocumentsList);
	ChangesInSpreadsheetDocuments.Insert("And", ModifiedSpreadsheetDocumentsList);
	
	For Each ValueTableRow In RemainingSpreadsheetDocumentsList Do
		
		SpreadsheetDocumentName = ValueTableRow.Value;
		
		XMLSprDoc = ObjectsVersioning.SerializeObject(
			New ValueStorage(SpreadsheetDocuments0[SpreadsheetDocumentName].Data));
		Checksum0 = ObjectsVersioning.Checksum(XMLSprDoc);
		
		XMLSprDoc = ObjectsVersioning.SerializeObject(
			New ValueStorage(SpreadsheetDocuments1[SpreadsheetDocumentName].Data));
		Checksum1 = ObjectsVersioning.Checksum(XMLSprDoc);
		
		If Checksum0 <> Checksum1 Then
			FillPropertyValues(ModifiedSpreadsheetDocumentsList.Add(), ValueTableRow);
		EndIf;
		
	EndDo;
	
	TabularSectionModifications = New Structure;
	TabularSectionModifications.Insert("d", TSToAddList);
	TabularSectionModifications.Insert("u", DeletedTSList);
	TabularSectionModifications.Insert("And", ChangesInTables);
	
	ChangesComposition = New Map;
	ChangesComposition.Insert("Attributes",      ChangesInAttributes);
	ChangesComposition.Insert("TabularSections", TabularSectionModifications);
	ChangesComposition.Insert("SpreadsheetDocuments", ChangesInSpreadsheetDocuments);
	
	Return ChangesComposition;
	
EndFunction

Procedure PrepareAttributeChangeTableColumns(ValueTable,
                                                      VersionNumberArray)
	
	ValueTable = New ValueTable;
	
	ValueTable.Columns.Add("Description");
	ValueTable.Columns.Add(NameOfModificationColumn());
	ValueTable.Columns.Add(NameOfValueTypeColumn()); // Expected value type.
	
	For IndexOf = 1 To VersionNumberArray.Count() Do
		ValueTable.Columns.Add("Version" + Format(VersionNumberArray[IndexOf-1], "NG=0"));
	EndDo;
	
EndProcedure

// Parameters:
//   ChangedTSList - ValueTable:
//   * Value - String 
//   TabularSections_0 - Map of KeyAndValue:
//   * Key - String 
//   * Value - ValueTable 
//   TabularSections_1 - Map of KeyAndValue:
//   * Key - String
//   * Value - ValueTable
// 
// Returns:
//   Map
//
Function CalculateChangesInTabularSections(ChangedTSList, TabularSections_0, TabularSections_1)
	
	For Each TabularSection In TabularSections_0 Do
		If TabularSections_1[TabularSection.Key] = Undefined Then
			TabularSections_1.Insert(TabularSection.Key, New ValueTable);
			DeletedTabularSection = ChangedTSList.Add();
			DeletedTabularSection.Value = TabularSection.Key;
		EndIf;
	EndDo;
	
	For Each TabularSection In TabularSections_1 Do
		If TabularSections_0[TabularSection.Key] = Undefined Then
			TabularSections_0.Insert(TabularSection.Key, New ValueTable);
			AddedTabularSection = ChangedTSList.Add();
			AddedTabularSection.Value = TabularSection.Key;
		EndIf;
	EndDo;
	
	ChangesInTables = New Map;
	
	// Repeating for each tabular section.
	For IndexOf = 1 To ChangedTSList.Count() Do
		
		ChangesInTables.Insert(ChangedTSList[IndexOf-1].Value, New Map);
		
		TableToAnalyze = ChangedTSList[IndexOf-1].Value;
		TS0 = TabularSections_0[TableToAnalyze];
		TS1 = TabularSections_1[TableToAnalyze];
		
		ChangedRowsTable = New ValueTable;
		ChangedRowsTable.Columns.Add("IndexInTS0");
		ChangedRowsTable.Columns.Add("IndexInTS1");
		ChangedRowsTable.Columns.Add("Differences1");
		
		TS0RowsAndTS1RowsMap = MapTableRows(TS0, TS1);
		TS1RowsAndTS0RowsMap = New Map;
		ColumnsToCheck = FindCommonColumns(TS0, TS1);
		For Each Map In TS0RowsAndTS1RowsMap Do
			TableRow0 = Map.Key;
			TableRow1 = Map.Value;
			DifferencesBetweenRows = DifferencesBetweenRows(TableRow0, TableRow1, ColumnsToCheck);
			If DifferencesBetweenRows.Count() > 0 Then
				NewRow = ChangedRowsTable.Add();
				NewRow["IndexInTS0"] = RowIndex(TableRow0) + 1;
				NewRow["IndexInTS1"] = RowIndex(TableRow1) + 1;
				NewRow["Differences1"] = DifferencesBetweenRows;
			EndIf;
			TS1RowsAndTS0RowsMap.Insert(TableRow1, TableRow0);
		EndDo;
		
		AddedRowTable = New ValueTable;
		AddedRowTable.Columns.Add("IndexInTS1");
		
		For Each TableRow In TS1 Do
			If TS1RowsAndTS0RowsMap[TableRow] = Undefined Then
				NewRow = AddedRowTable.Add();
				NewRow.IndexInTS1 = TS1.IndexOf(TableRow) + 1;
			EndIf;
		EndDo;
		
		DeletedRowTable = New ValueTable;
		DeletedRowTable.Columns.Add("IndexInTS0");
		
		For Each TableRow In TS0 Do
			If TS0RowsAndTS1RowsMap[TableRow] = Undefined Then
				NewRow = DeletedRowTable.Add();
				NewRow.IndexInTS0 = TS0.IndexOf(TableRow) + 1;
			EndIf;
		EndDo;
		
		ChangesInTables[ChangedTSList[IndexOf-1].Value].Insert("D", AddedRowTable);
		ChangesInTables[ChangedTSList[IndexOf-1].Value].Insert("U", DeletedRowTable);
		ChangesInTables[ChangedTSList[IndexOf-1].Value].Insert("And", ChangedRowsTable);
		
	EndDo;
	
	Return ChangesInTables;
	
EndFunction

Function FindChangedTabularSections(RemainingTSList,
                                        TabularSections_0,
                                        TabularSections_1)
	
	ChangedTSList = CreateComparisonChart();
	
	// Searching for tabular sections with changed rows.
	For Each Item In RemainingTSList Do
		
		TS_0 = TabularSections_0[Item.Value];
		TS_1 = TabularSections_1[Item.Value];
		
		If TS_0.Count() = TS_1.Count() Then
			
			DifferenceFound = False;
			
			// Making sure the column structure remains the same.
			If TabularSectionsEqual (TS_0.Columns, TS_1.Columns) Then
				
				// Searching for differing items - rows.
				For IndexOf = 0 To TS_0.Count() - 1 Do
					String_0 = TS_0[IndexOf];
					String_1 = TS_1[IndexOf];
					
					If Not TSRowsEqual(String_0, String_1, TS_0.Columns) Then
						DifferenceFound = True;
						Break;
					EndIf
				EndDo;
				
			Else
				DifferenceFound = True;
			EndIf;
			
			If DifferenceFound Then
				NewRow = ChangedTSList.Add();
				NewRow.Set(0, Item.Value);
			EndIf;
			
		Else
			NewRow = ChangedTSList.Add();
			NewRow.Set(0, Item.Value);
		EndIf;
			
	EndDo;
	
	Return ChangedTSList;
	
EndFunction

Function CountInitialAttributeAndTabularSectionValues(AttributesTable, TableTS, VersionsCount, VersionNumberArray, ObjectReference)
	
	JuniorObjectVersion = VersionNumberArray[0];
	
	// Parsing the first version.
	ObjectVersion  = ObjectsVersioning.ParseVersion(ObjectReference, JuniorObjectVersion);
	AddRowNumbersToTabularSections(ObjectVersion.TabularSections);
	
	Attributes      = ObjectVersion.Attributes;
	TabularSections = ObjectVersion.TabularSections;
	
	Column = "Version" + Format(VersionNumberArray[0], "NG=0");
	
	For Each ValueTableRow In Attributes Do
		
		NewRow = AttributesTable.Add();
		NewRow[Column] = New Structure("ChangeKind, Value", "And", ValueTableRow);
		NewRow.Description = ValueTableRow.AttributeDescription;
		NewRow[NameOfModificationColumn()] = False;
		NewRow[NameOfValueTypeColumn()] = ValueTableRow.AttributeType;
		
	EndDo;
	
	For Each TSItem In TabularSections Do
		
		TableTS.Insert(TSItem.Key, New Map);
		PrepareChangeTableColumnsForMapping(TableTS[TSItem.Key], VersionNumberArray);
		TableTS[TSItem.Key]["Version" + Format(JuniorObjectVersion, "NG=0")] = TSItem.Value.Copy();
		
		CurrentVT = TableTS[TSItem.Key]["Version" + Format(JuniorObjectVersion, "NG=0")];// ValueTable
		
		CurrentVT.Columns.Add(NameOfLineIDColumn());
		CurrentVT.Columns.Add(NameOfModificationColumn());
		CurrentVT.Columns.Add(NameOfChangesColumn(), New TypeDescription("Array"));
		
		For IndexOf = 1 To CurrentVT.Count() Do
			CurrentVT[IndexOf-1][InternalColumnPrefix() + "LineID"] = IndexOf;
			CurrentVT[IndexOf-1][InternalColumnPrefix() + "Modification"] = False;
		EndDo;
	
	EndDo;
	
	Return ObjectVersion;
	
EndFunction

Procedure PrepareChangeTableColumnsForMapping(Map, VersionNumberArray)
	
	Count = VersionNumberArray.Count();
	
	For IndexOf = 1 To Count Do
		Map.Insert("Version" + Format(VersionNumberArray[IndexOf-1], "NG=0"), New ValueTable);
	EndDo;
	
EndProcedure

Function TabularSectionsEqual(FirstTableColumns, SecondTableColumns)
	If FirstTableColumns.Count() <> SecondTableColumns.Count() Then
		Return False;
	EndIf;
	
	For Each Column In FirstTableColumns Do
		Found2 = SecondTableColumns.Find(Column.Name);
		If Found2 = Undefined Or Column.ValueType <> Found2.ValueType Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
EndFunction

// Parameters:
//   TSRow1 - ValueTableRow
//   TSRow2 - ValueTableRow
//   Columns - ValueTableColumnCollection
// Returns:
//   Boolean
//
Function TSRowsEqual(TSRow1, TSRow2, Columns)
	
	For Each Column In Columns Do
		ColumnName = Column.Name;
		If TSRow2.Owner().Columns.Find(ColumnName) = Undefined Then
			Continue;
		EndIf;
		ValueFromTS1 = TSRow1[ColumnName];
		ValueFromTS2 = TSRow2[ColumnName];
		If ValueFromTS1 <> ValueFromTS2 Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

Function GetVersionDetails(ObjectReference, VersionNumber)
	
	VersionInfo = ObjectsVersioning.ObjectVersionInfo(ObjectReference, VersionNumber.Value);
	
	LongDesc = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Số %1 / (%2) / %3';
																			|ru = '№ %1 / (%2) / %3';
																			|en = '#%1 / (%2) / %3'; fa = '#%1 / (%2) / %3';
																			|it = '№ %1 / (%2) / %3';
																			|pl = '№ %1 / (%2) / %3';
																			|tr = '№ %1 / (%2) / %3'"), VersionNumber.Presentation, 
		String(VersionInfo.VersionDate), TrimAll(String(VersionInfo.VersionAuthor)));
		
	VersionInfo.Insert("LongDesc", LongDesc);
	
	Return VersionInfo;
	
EndFunction

Function CalculateChangedAttributeCount(ChangesTableBankingDetails_, VersionNumberArray)
	
	Result = 0;
	
	For Each VTItem1 In ChangesTableBankingDetails_ Do
		If VTItem1[NameOfModificationColumn()] <> Undefined And VTItem1[NameOfModificationColumn()] = True Then
			Result = Result + 1;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function IncreaseCounter(counterUniqueID, TableName);
	
	counterUniqueID[TableName] = counterUniqueID[TableName] + 1;
	
	Return counterUniqueID[TableName];
	
EndFunction

Function GetUUID(ChangesTableTS, VersionColumnName)
	
	MapUUID = New Map;
	
	For Each ItemMap In ChangesTableTS Do
		MapUUID[ItemMap.Key] = Number(ItemMap.Value[VersionColumnName].Count());
	EndDo;
	
	Return MapUUID;
	
EndFunction

Procedure FillAttributeChangingCharacteristic(SingleAttributeChangeTable, 
                                                    ChangeFlag,
                                                    ChangesTableBankingDetails_,
                                                    CurrentVersionColumnName,
                                                    ObjectVersion)
	
	For Each Item In SingleAttributeChangeTable Do
		Description = Item.Value;
		AttributeChange = ChangesTableBankingDetails_.Find (Description, "Description");
		
		If AttributeChange = Undefined Then
			AttributeChange = ChangesTableBankingDetails_.Add();
			AttributeChange.Description = Description;
		EndIf;
		
		ChangeParameters = New Structure;
		ChangeParameters.Insert("ChangeKind", ChangeFlag);
		
		If ChangeFlag = "u" Then
			ChangeParameters.Insert("Value", "deleted");
		Else
			ChangeParameters.Insert("Value", ObjectVersion.Attributes.Find(Description, "AttributeDescription"));
		EndIf;
		
		AttributeChange[CurrentVersionColumnName] = ChangeParameters;
		AttributeChange[NameOfModificationColumn()] = True;
	EndDo;
	
EndProcedure


Function GenerateTSRowSector(CommonTemplate, Val FillingValues, Val OutputType = "")
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	If      OutputType = ""  Then
		Template = CommonTemplate.GetArea("InitialAttributeValue");
	ElsIf OutputType = "And" Then
		Template = CommonTemplate.GetArea("ModifiedAttributeValue");
	ElsIf OutputType = "D" Then
		Template = CommonTemplate.GetArea("AddedAttribute");
	ElsIf OutputType = "U" Then
		Template = CommonTemplate.GetArea("DeletedAttribute");
	EndIf;
	
	TemplateNoChanges = CommonTemplate.GetArea("InitialAttributeValue");
	TemplateHasChange = CommonTemplate.GetArea("ModifiedAttributeValue");
	
	HasDetails = TypeOf(FillingValues) = Type("ValueList");
	For Each Item In FillingValues Do
		Value = Item;
		If HasDetails And OutputType = "And" Then
			Value = Item.Presentation;
			IsUpdate = Item.Value;
			Template = ?(IsUpdate, TemplateHasChange, TemplateNoChanges);
		EndIf;
		Template.Parameters.AttributeValue = Value;
		SpreadsheetDocument.Put(Template);
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

Function GenerateEmptySector(CommonTemplate, Val CountOfRows, Val OutputType = "")
	
	FillValue = New Array;
	
	For IndexOf = 1 To CountOfRows Do
		FillValue.Add(" ");
	EndDo;
	
	Return GenerateTSRowSector(CommonTemplate, FillValue, OutputType);
	
EndFunction

Function SubtractTable(Val TableMain,
                       Val DeductedTable,
                       Val MainTableComparisonColumn = "",
                       Val SubtractTableComparisonColumn = "")
	
	If Not ValueIsFilled(MainTableComparisonColumn) Then
		MainTableComparisonColumn = "Value";
	EndIf;
	
	If Not ValueIsFilled(SubtractTableComparisonColumn) Then
		SubtractTableComparisonColumn = "Value";
	EndIf;
	
	ResultTable1 = New ValueTable;
	ResultTable1 = TableMain.Copy();
	
	For Each Item In DeductedTable Do
		Value = Item[MainTableComparisonColumn];
		FoundRow = ResultTable1.Find(Value, MainTableComparisonColumn);
		If FoundRow <> Undefined Then
			ResultTable1.Delete(FoundRow);
		EndIf;
	EndDo;
	
	Return ResultTable1;
	
EndFunction

Function CreateComparisonChart(InitializationTable = Undefined,
                                ComparisonColumnName = "Value")
	
	Table = New ValueTable;
	Table.Columns.Add(ComparisonColumnName);
	
	If InitializationTable <> Undefined Then
		
		For Each Item In InitializationTable Do
			NewRow = Table.Add();
			NewRow.Set(0, Item[ComparisonColumnName]);
		EndDo;
		
	EndIf;
	
	Return Table;

EndFunction


// Parameters:
//   TableRow - ValueTableRow
//
Function RowIndex(TableRow)
	Return TableRow.Owner().IndexOf(TableRow);
EndFunction

Procedure AddRowNumbersToTabularSections(TabularSections)
	
	For Each Map In TabularSections Do
		Table = Map.Value;// ValueTable
		If Table.Columns.Find("LineNumber") <> Undefined Then
			Continue;
		EndIf;
		Table.Columns.Insert(0, "LineNumber",,NStr("vi = 'Số dòng';
													|ru = '№ строки';
													|en = '#'; fa = '#';
													|it = '№ di riga';
													|pl = 'Nr wiersza';
													|tr = 'Satır No'"));
		For LineNumber = 1 To Table.Count() Do
			Table[LineNumber-1].LineNumber = LineNumber;
		EndDo;
	EndDo;
	
EndProcedure

Function FindSimilarTableRows(Val Table1, Val Table2, Val RequiredDifferenceCount = 0, Val MaxDifferences = Undefined, Table1RowsAndTable2RowsMap = Undefined)
	
	Ignore = "Ignore_";
	
	If Table1.Columns.Find(Ignore) = Undefined Then
		Table1 = Table1.Copy();
		Table1.Columns.Add(Ignore, New TypeDescription("Boolean"));
		Table1.Indexes.Add(Ignore);
	EndIf;
	
	If Table2.Columns.Find(Ignore) = Undefined Then
		Table2 = Table2.Copy();
		Table2.Columns.Add(Ignore, New TypeDescription("Boolean"));
		Table2.Indexes.Add(Ignore);
	EndIf;
	
	If Table1RowsAndTable2RowsMap = Undefined Then
		Table1RowsAndTable2RowsMap = New Map;
	EndIf;
	
	If MaxDifferences = Undefined Then
		MaxDifferences = MaxTableRowDifferenceCount(Table1, Table2);
	EndIf;
	
	CommonColumns = FindCommonColumns(Table1, Table2);
	OtherColumns = FindNonmatchingColumns(Table1, Table2);
	
	For Each TableRow1 In Table1.FindRows(New Structure(Ignore, False)) Do
		For Each TableRow2 In Table2.FindRows(New Structure(Ignore, False)) Do
			DifferenceCount = DifferenceCountInTableRows(TableRow1, TableRow2, CommonColumns, OtherColumns);
			
			If DifferenceCount = RequiredDifferenceCount Then
				Table1RowsAndTable2RowsMap.Insert(TableRow1.LineNumber, TableRow2.LineNumber);
				TableRow1[Ignore] = True;
				TableRow2[Ignore] = True;
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	If Table1RowsAndTable2RowsMap.Count() < Table1.Count() And Table2.FindRows(New Structure(Ignore, False)).Count() > 0 Then
		If RequiredDifferenceCount < MaxDifferences Then
			FindSimilarTableRows(Table1, Table2, RequiredDifferenceCount + 1, MaxDifferences, Table1RowsAndTable2RowsMap);
		EndIf;
	EndIf;
	
	Return Table1RowsAndTable2RowsMap;
	
EndFunction

Function MapTableRows(Table1, Table2)
	MapRowNumbers = FindSimilarTableRows(Table1, Table2);
	Result = New Map;
	For Each Item In MapRowNumbers Do
		Result.Insert(Table1[Item.Key - 1], Table2[Item.Value - 1]);
	EndDo;
	Return Result;
EndFunction

Function MaxTableRowDifferenceCount(Table1, Table2)
	
	TableColumnNameArray1 = GetColumnNames(Table1);
	TableColumnNameArray2 = GetColumnNames(Table2);
	BothTablesColumnNameArray = MergeSets(TableColumnNameArray1, TableColumnNameArray2);
	TotalColumns = BothTablesColumnNameArray.Count();
	
	Return ?(TotalColumns = 0, 0, TotalColumns - 1);

EndFunction

Function MergeSets(Set1, Set2)
	
	Result = New Array;
	
	For Each Item In Set1 Do
		IndexOf = Result.Find(Item);
		If IndexOf = Undefined Then
			Result.Add(Item);
		EndIf;
	EndDo;
	
	For Each Item In Set2 Do
		IndexOf = Result.Find(Item);
		If IndexOf = Undefined Then
			Result.Add(Item);
		EndIf;
	EndDo;	
	
	Return Result;
	
EndFunction

Function GetColumnNames(Table)
	
	Result = New Array;
	
	For Each Column In Table.Columns Do
		Result.Add(Column.Name);
	EndDo;
	
	Return Result;
	
EndFunction

Function DifferenceCountInTableRows(TableRow1, TableRow2, CommonColumns, OtherColumns)
	
	// Counting each unmapped column as a single difference.
	Result = OtherColumns.Count();
	
	// Counting differences by non-matching values.
	For Each ColumnName In CommonColumns Do
		If TableRow1[ColumnName] <> TableRow2[ColumnName] Then
			Result = Result + 1;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function FindCommonColumns(Table1, Table2)
	NamesArray1 = GetColumnNames(Table1);
	NamesArray2 = GetColumnNames(Table2);
	Return SetIntersection(NamesArray1, NamesArray2);
EndFunction

Function FindNonmatchingColumns(Table1, Table2)
	NamesArray1 = GetColumnNames(Table1);
	NamesArray2 = GetColumnNames(Table2);
	Return SetDifference(NamesArray1, NamesArray2, True);
EndFunction

Function SetDifference(Set1, Val Set2, SymmetricDifference = False)
	
	Result = New Array;
	Set2 = CopyArray(Set2);
	
	For Each Item In Set1 Do
		IndexOf = Set2.Find(Item);
		If IndexOf = Undefined Then
			Result.Add(Item);
		Else
			Set2.Delete(IndexOf);
		EndIf;
	EndDo;
	
	If SymmetricDifference Then
		For Each Item In Set2 Do
			Result.Add(Item);
		EndDo;
	EndIf;
	
	Return Result;
EndFunction

Function SetIntersection(Set1, Set2)
	
	Result = New Array;
	
	For Each Item In Set1 Do
		IndexOf = Set2.Find(Item);
		If IndexOf <> Undefined Then
			Result.Add(Item);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function CopyArray(Source)
	
	Result = New Array(Source.Count());
	For IndexOf = 0 To Source.UBound() Do
		Result[IndexOf] = Source[IndexOf];
	EndDo;
	Return Result;
	
EndFunction

Function DifferencesBetweenRows(String1, String2, ColumnsToCheck)
	Result = New Array;
	For Each Column In ColumnsToCheck Do
		If TypeOf(String1[Column]) = Type("ValueStorage") Then
			Continue; // Attributes with the ValueStorage type are not compared.
		EndIf;
		If String1[Column] <> String2[Column] Then
			Result.Add(Column);
		EndIf;
	EndDo;
	Return Result;
EndFunction


// Progress of the synchronization warnings deletion
// 
Procedure ProgressDeletingSyncAlerts(Val CurrentStep, Max, SampleIterator = 0)
	
	CurrentStep = ?(CurrentStep = 0, 1, CurrentStep);
	
	If SampleIterator = 0 Then
		
		Template = NStr("vi = 'Đã thực hiện lặp lại %1 trong số %2';
						|ru = 'Выполнено итераций %1 из %2';
						|en = '%1 out of %2 iterations completed'; fa = '%1 out of %2 iterations completed';
						|it = 'Eseguite %1 iterazioni di %2';
						|pl = 'Wykonano iteracji %1 z %2';
						|tr = 'Tamamlanan iterasyon %1 / %2'",  Common.DefaultLanguageCode());
		ProgressText = StringFunctionsClientServer.SubstituteParametersToString(Template, CurrentStep, Max);
		
	Else
		
		Template = NStr("vi = 'Đã thực hiện lặp lại %1 trong số %2 (%3)';
						|ru = 'Выполнено итераций %1 из %2 (%3)';
						|en = '%1 out of %2 iterations completed (%3)'; fa = '%1 out of %2 iterations completed (%3)';
						|it = 'Iterazioni eseguite %1 di %2 (%3)';
						|pl = 'Wykonano iteracji %1 z %2 (%3)';
						|tr = 'Tamamlanan iterasyon %1 / %2 (%3)'",  Common.DefaultLanguageCode());
		ProgressText = StringFunctionsClientServer.SubstituteParametersToString(
			Template, CurrentStep, Max, SampleIterator);
		
	EndIf;
	
	ProgressPercent = Round(CurrentStep * 100 / Max, 0);
	TimeConsumingOperations.ReportProgress(ProgressPercent, ProgressText);
	
EndProcedure

Procedure ClearVersionWarnings(DeletionParameters, EventName) Export
	
	Query = New Query;
	Query.SetParameter("ObjectVersionType", DeletionParameters.SelectingTheTypesOfVersionWarnings);
	
	Query.Text =
	"SELECT
	|	ObjectVersionRegister.Object AS BlockingObject,
	|	ObjectVersionRegister.VersionNumber AS VersionNumber
	|FROM
	|	InformationRegister.ObjectsVersions AS ObjectVersionRegister
	|WHERE
	|	ObjectVersionRegister.ObjectVersionType IN(&ObjectVersionType)
	|TOTALS BY
	|	BlockingObject";
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(Query.Text);
	
	TheOperatorOfTheRequestSchema = QuerySchema.QueryBatch[0].Operators[0];
	
	If DeletionParameters.SelectionOfExchangePlanNodes.Count() > 0 Then
		
		TheOperatorOfTheRequestSchema.Filter.Add("VersionAuthor IN(&SelectionOfExchangePlanNodes)");
		Query.SetParameter("SelectionOfExchangePlanNodes", DeletionParameters.SelectionOfExchangePlanNodes);
		
	EndIf;
	
	ValueOfTheDeleteParameter = DeletionParameters.SelectionByDateOfOccurrence;// StandardPeriod
	If ValueIsFilled(ValueOfTheDeleteParameter) Then
		
		TheOperatorOfTheRequestSchema.Filter.Add("VersionDate BETWEEN &StartDate AND &EndDate");
		Query.SetParameter("StartDate", ValueOfTheDeleteParameter.StartDate);
		Query.SetParameter("EndDate", ValueOfTheDeleteParameter.EndDate);
		
	EndIf;
	
	If DeletionParameters.OnlyHiddenRecords Then
		
		TheOperatorOfTheRequestSchema.Filter.Add("VersionIgnored = TRUE");
		
	EndIf;
	
	Query.Text = QuerySchema.GetQueryText();
	SelectionOfObjects = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	ObjectCount = SelectionOfObjects.Count();
	If ObjectCount < 1 Then
		
		Return;
		
	EndIf;
	
	Proportion = DeletionParameters.SelectingTheTypesOfVersionWarnings.Count() / ObjectCount;
	SampleIterator = 0;
	
	RecordsetResults = InformationRegisters.ObjectsVersions.CreateRecordSet();
	
	While SelectionOfObjects.Next() Do
		
		// 1. Start a transaction of two operations: register read and write.
		BeginTransaction();
		Try
			
			 // 2. Set an exclusive lock on the required range of register records to make sure that
			 // the warning count hasn't changed in another session at the recording time.
			 // 
			DataLock = New DataLock;
			DataLockItem = DataLock.Add("InformationRegister.ObjectsVersions");
			DataLockItem.SetValue("Object", SelectionOfObjects.BlockingObject);
			DataLock.Lock();
			
			// 3. Read the information register.
			RecordsetResults.Filter.Object.Set(SelectionOfObjects.BlockingObject, True);
			
			SelectingTheVersionNumber = SelectionOfObjects.Select();
			While SelectingTheVersionNumber.Next() Do
				
				RecordsetResults.Filter.VersionNumber.Set(SelectingTheVersionNumber.VersionNumber, True);
				
				// 4. Write the information register.
				RecordsetResults.Write(True);
				
			EndDo;
			
			SampleIterator = SampleIterator + 1;
			If Round(SampleIterator * Proportion, 0) <> Round((SampleIterator - 1) * Proportion, 0) Then 
				
				// Increase the step proportionally (when the number of iterations multiplied by the ratio change the value).
				DeletionParameters.NumberOfOperationsCurrentStep = DeletionParameters.NumberOfOperationsCurrentStep + 1;
				
			EndIf;
			
			ProgressDeletingSyncAlerts(DeletionParameters.NumberOfOperationsCurrentStep, DeletionParameters.MaximumNumberOfOperations, SampleIterator);
			
			CommitTransaction();
			
		Except
			
			// 5. If the register is already locked in another session (or another exceptional issue happened),
			// roll back the transaction and log the error.
			RollbackTransaction();
			
			WriteLogEvent(EventName, EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Raise;
			
		EndTry;
		
	EndDo;
	
EndProcedure

Procedure RemovePreviousWarningExchanges(ObjectVersionInfo) Export
	
	// The following approaches are accepted:
	// 1. If the warning type relates to synchronization, clean up by type.
	// 2. If synchronization comments are found, clear all similar comments.
	//
	// In both approaches, delete records where the conditions match and the user is their author
	// since it is impossible to determine which exchange the warning belongs to.
	
	AcceptableTypesOfWarnings = New Array;
	AcceptableTypesOfWarnings.Add(Enums.ObjectVersionTypes.ConflictDataAccepted);
	AcceptableTypesOfWarnings.Add(Enums.ObjectVersionTypes.RejectedConflictData);
	AcceptableTypesOfWarnings.Add(Enums.ObjectVersionTypes.RejectedDueToPeriodEndClosingDateObjectExistsInInfobase);
	AcceptableTypesOfWarnings.Add(Enums.ObjectVersionTypes.RejectedDueToPeriodEndClosingDateObjectDoesNotExistInInfobase);
	
	Try
		
		If AcceptableTypesOfWarnings.Find(ObjectVersionInfo.ObjectVersionType) <> Undefined Then
			
			RemovePreviousExchangeWarningsByType(ObjectVersionInfo, AcceptableTypesOfWarnings);
			
		EndIf;
		
		If Not IsBlankString(ObjectVersionInfo.SynchronizationWarning) Then
			
			DeletePreviousWarningExchangesByComment(ObjectVersionInfo);
			
		EndIf;
		
	Except
		
		EventName = NStr("vi = 'Trao đổi dữ liệu';
						|ru = 'Обмен данными';
						|en = 'Data exchange'; fa = 'تبادل داده';
						|it = 'Обмен данными';
						|pl = 'Wymiana danych';
						|tr = 'Veri değişimi'", Common.DefaultLanguageCode());
		WriteLogEvent(EventName, EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndProcedure

Procedure RemovePreviousExchangeWarningsByType(ObjectVersionInfo, AcceptableTypesOfWarnings)
	
	Query = New Query;
	Query.SetParameter("Object", ObjectVersionInfo.Object);
	Query.SetParameter("ObjectVersionType", ObjectVersionInfo.ObjectVersionType);
	
	If ValueIsFilled(ObjectVersionInfo.VersionAuthor)
		And TypeOf(ObjectVersionInfo.VersionAuthor) <> Type("CatalogRef.Users") Then
		
		Query.SetParameter("AuthorOfVersionIsSubAsset", ObjectVersionInfo.VersionAuthor);
		
	Else
		
		Query.SetParameter("AuthorOfVersionIsSubAsset", Undefined);
		
	EndIf;
	
	Query.Text =
		"SELECT TOP 10
		|	ObjectsVersions.Object AS Object,
		|	ObjectsVersions.VersionNumber AS VersionNumber
		|FROM
		|	InformationRegister.ObjectsVersions AS ObjectsVersions
		|WHERE
		|	ObjectsVersions.Object = &Object
		|	AND ObjectsVersions.ObjectVersionType = &ObjectVersionType
		|	AND (ObjectsVersions.VersionAuthor = &AuthorOfVersionIsSubAsset
		|			OR ObjectsVersions.VersionAuthor REFS Catalog.Users)
		|
		|ORDER BY
		|	ObjectsVersions.VersionNumber";
	
	Selection = Query.Execute().Select();
	While Selection.Count() > 0 Do
		
		While Selection.Next() Do
			
			RecordManager = CreateRecordManager();
			RecordManager.Object = Selection.Object;
			RecordManager.VersionNumber = Selection.VersionNumber;
			RecordManager.Delete();
			
		EndDo;
		
		If TransactionActive() Then
			
			Break;
			
		EndIf;
		
		Selection = Query.Execute().Select(); // @skip-check query-in-loop - Batch processing of a large amount of data.
		
	EndDo;
	
EndProcedure

Procedure DeletePreviousWarningExchangesByComment(ObjectVersionInfo)
	
	Query = New Query;
	Query.SetParameter("Object", ObjectVersionInfo.Object);
	Query.SetParameter("SynchronizationWarning", ObjectVersionInfo.SynchronizationWarning);
	
	Query.Text = 
		"SELECT TOP 100
		|	ObjectsVersions.Object AS Object,
		|	ObjectsVersions.VersionNumber AS VersionNumber
		|FROM
		|	InformationRegister.ObjectsVersions AS ObjectsVersions
		|WHERE
		|	ObjectsVersions.Object = &Object
		|	AND (CAST(ObjectsVersions.SynchronizationWarning AS STRING(512))) = &SynchronizationWarning
		|
		|ORDER BY
		|	ObjectsVersions.VersionNumber";
	
	Selection = Query.Execute().Select();
	While Selection.Count() > 0 Do
		
		While Selection.Next() Do
			
			RecordManager = CreateRecordManager();
			RecordManager.Object = Selection.Object;
			RecordManager.VersionNumber = Selection.VersionNumber;
			RecordManager.Delete();
			
		EndDo;
		
		If TransactionActive() Then
			
			Break;
			
		EndIf;
		
		Selection = Query.Execute().Select(); // @skip-check query-in-loop - Batch processing of a large amount of data.
		
	EndDo;
	
EndProcedure

Function InternalColumnPrefix()
	
	Return "Versioning_";
	
EndFunction

Function NameOfLineIDColumn()

	Return InternalColumnPrefix() + "LineID";

EndFunction

Function NameOfModificationColumn()

	Return InternalColumnPrefix() + "Modification";

EndFunction

Function NameOfChangesColumn()

	Return InternalColumnPrefix() + "Changes";

EndFunction

Function NameOfValueTypeColumn()

	Return InternalColumnPrefix() + "ValueType";

EndFunction

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("GenerateReportOnChanges", True);
	
EndProcedure

#EndRegion

#EndIf