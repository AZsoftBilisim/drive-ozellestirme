//@strict-types

#Region Public

// Returns a reference to the new selection group in the transmitted data layout schema selection.
//
// Parameters:
//  Filter - DataCompositionFilter - the selection of the layout to which you want to add a new item
//  GroupType - DataCompositionFilterItemsGroupType, Undefined - the type of group to create (by default, OR) 
//  
// Returns:
//  DataCompositionFilter - a link to a new selection element of the data layout scheme.
//
Function NewFiltersGroup(Filter, GroupType = Undefined) Export
	
	NewFolder = FinancialReportingServer.NewFilter(
		Filter, Undefined,, Type("DataCompositionFilterItemGroup")); // DataCompositionFilter
	
	If GroupType = Undefined Then
		NewFolder.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Else
		NewFolder.GroupType = GroupType;
	EndIf; 
	
	Return NewFolder;
	
EndFunction

// Returns the last agreed and executed document of the terms of retro bonuses for the root document of the chain 
// 
// Parameters:
//  Document - DocumentObject.ConditionsOfCustomerRebates, DocumentObject.ConditionsOfVendorRebates - The document for which it is required to obtain an up-to-date (valid) corrective document of the terms of retro bonuses
// 
// Returns:
//  QueryResultSelection:
//	* Ref - DocumentRef.ConditionsOfCustomerRebates, DocumentRef.ConditionsOfVendorRebates -
// 
Function UpToDateDocumentOfRebatesTermsAndConditions(Document) Export
	
	Query = New Query;
	QueryText =
	"SELECT TOP 1
	|	DocumentsRegistry.Ref AS Ref
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.CorrectedDocument = &CorrectedDocument
	|	AND DocumentsRegistry.Ref <> &CorrectiveDocument
	|	AND NOT DocumentsRegistry.AdditionalRecord
	|	AND DocumentsRegistry.Posted
	|	AND DocumentsRegistry.Status = VALUE(Enum.RebatesDocumentStatuses.Approved)
	|
	|ORDER BY
	|	DocumentsRegistry.IBDocumentDate DESC";
	Query.Text = QueryText;
	Query.SetParameter("CorrectedDocument", Document.CorrectedDocument);
	Query.SetParameter("CorrectiveDocument", Document.Ref);
	Selection = Query.Execute().Select();
	
	Return Selection;
	
EndFunction

// Returns the last completed document of the retro bonus conditions in the specified status for the root document of the chain.
// If the status is not specified, the last completed agreed document will be returned.
// If there is no correction document, the document itself will be returned. 
// 
// Parameters:
//  Document - DocumentRef.ConditionsOfCustomerRebates, DocumentRef.ConditionsOfVendorRebates - Link to the document for which you want to get an up-to-date (valid) document of the terms of retro bonuses
//  Status - EnumRef.RebatesDocumentStatuses, Undefined - Status of the last document in the chain
// 
// Returns:
//  DocumentRef.ConditionsOfCustomerRebates, DocumentRef.ConditionsOfVendorRebates -
// 
Function UpToDateDocumentOfRebatesTermsAndConditionsCanBeFoundAtLink(Document, Status = Undefined) Export
	
	If Status = Undefined Then
		DocumentStatus = Enums.RebatesDocumentStatuses.Approved;
	Else
		DocumentStatus = Status;
	EndIf;
	
	ManagerOfDocument = Common.ObjectManagerByRef(Document);
	QueryText = ManagerOfDocument.QueryTextOfCurrentConditionsDocument();
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("CorrectedDocument", Document);
	Query.SetParameter("DocumentStatus", DocumentStatus);
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		
		ActualDocument = ManagerOfDocument.EmptyRef();
		
	Else
		
		Selection = QueryResult.Select();
		Selection.Next();
		ActualDocument = Selection.Ref;
		
	EndIf;
	
	Return ActualDocument;
	
EndFunction

// See ReportsTMOverridable.SupplementComplianceOfTrafficReportRegistrars
//
Procedure SupplementComplianceOfTrafficReportRegistrars(Document, RegisterMatching) Export
	
	Registers = Metadata.InformationRegisters;
	
	If TypeOf(Document) = Type("DocumentRef.ConditionsOfCustomerRebates") Then
		
		RegisterMatching.Insert(Registers.CustomerRebatesTIN, "RecorderDocument");
		RegisterMatching.Insert(Registers.CustomerRebatesCounterparties, "RecorderDocument");
		RegisterMatching.Insert(Registers.CustomerRebatesPartnerSegments, "RecorderDocument");
		RegisterMatching.Insert(Registers.CustomerRebatesItemSegments, "RecorderDocument");
		RegisterMatching.Insert(Registers.CustomerRebatesItems, "RecorderDocument");
		RegisterMatching.Insert(Registers.CustomerRebatesItemProperties, "RecorderDocument");
		RegisterMatching.Insert(Registers.CustomerRebatesConditions, "RecorderDocument");
		RegisterMatching.Insert(Registers.CustomerRebatesContractsTermsOfSales, "RecorderDocument");
		RegisterMatching.Insert(Registers.RebatesCalculationScales, "RecorderDocument");
		
	EndIf;
	
	If TypeOf(Document) = Type("DocumentRef.ConditionsOfVendorRebates") Then
		
		RegisterMatching.Insert(Registers.VendorRebatesTIN, "RecorderDocument");
		RegisterMatching.Insert(Registers.VendorRebatesGoodsSegments, "RecorderDocument");
		RegisterMatching.Insert(Registers.VendorRebatesGoods, "RecorderDocument");
		RegisterMatching.Insert(Registers.VendorRebatesItemProperties, "RecorderDocument");
		RegisterMatching.Insert(Registers.VendorRebatesConditions, "RecorderDocument");
		RegisterMatching.Insert(Registers.VendorRebatesCounterparties, "RecorderDocument");
		RegisterMatching.Insert(Registers.VendorRebatesVendors, "RecorderDocument");
		RegisterMatching.Insert(Registers.VendorRebatesWarehouses, "RecorderDocument");
		RegisterMatching.Insert(Registers.RebatesCalculationScales, "RecorderDocument");
		
	EndIf;
	
EndProcedure

// The procedure checks duplicates of rows in the table part
//
// Parameters:
//  Object - DocumentObject, ClientApplicationForm - document object or form being checked
//  TSName - String - name of the table part to check
//  KeyDetailsOfTS - Array of String -
//	                    - String - array of the names of the details by which the uniqueness of the string is determined
//	                    - Structure - The key is the name of the Attribute, the value is the Presentation of the Attribute
//  Cancel - Boolean - failure to continue the operation.
//  PresentationOfTS - String - if not specified, the view will be obtained from the metadata.
//  SpecifyLineNumbers - Boolean - specifies whether to display the line number in the error message.
//  RowFilter - Structure - if not specified, then all rows from the table part are selected, otherwise - according to the selection:
//  	* Key - String
//  	* Value - Arbitrary
//
Procedure CheckForDuplicatesOfTSStrings(Object, TSName, KeyDetailsOfTS, Cancel, PresentationOfTS = "", SpecifyLineNumbers = True, RowFilter = Undefined) Export
	
	ValueTypeKeyDetailsTS = TypeOf(KeyDetailsOfTS);
	PresentationOfAttributeFromSynonym = True;
	
	If ValueTypeKeyDetailsTS = Type("String") Then
		KeyAttributes = StrSplit(KeyDetailsOfTS, ",");
	ElsIf ValueTypeKeyDetailsTS = Type("Structure") Then
		
		PresentationOfAttributeFromSynonym = False;
		KeyAttributes = New Array; // Array of String
		For Each NameAndPresentationOfProps In KeyDetailsOfTS Do
			
			KeyAttributes.Add(NameAndPresentationOfProps.Key);
			
		EndDo;
		
	Else
		KeyAttributes = KeyDetailsOfTS;
	EndIf;
	
	DataKey = TMCommonUse.DataKeyForMessageToUser(Object);
	
	ThisIsForm = False;
	If TypeOf(Object) = Type("ClientApplicationForm") Then
		
		ThisIsForm = True;
		
	Else
		
		ObjectMetadata = Object.Metadata();
		If IsBlankString(PresentationOfTS) Then
			PresentationOfTS = ObjectMetadata.TabularSections[TSName].Synonym;
		EndIf;
		
	EndIf;
	
	ArrayOfRowsOfSelectionField = New Array; // Array of String
	ArrayOfConnectionFieldStrings = New Array; // Array of String
	ArrayOfRowsOfUploadField = New Array; // Array of String
	ArrayOfDuplicateMessageLines = New Array; // Array of String
	
	For Each ArrRow In KeyAttributes Do
		
		ArrayOfRowsOfSelectionField.Add(StrTemplate("CheckTable.%1", ArrRow));
		ArrayOfConnectionFieldStrings.Add(StrTemplate("CheckTable.%1 = DuplicateLines.%1", ArrRow));
		ArrayOfRowsOfUploadField.Add(ArrRow);
		
		If PresentationOfAttributeFromSynonym Then
			AttributeRepresentation = ?(ThisIsForm, "", ObjectMetadata.TabularSections[TSName].Attributes[ArrRow].Synonym);
		Else
			AttributeRepresentation = ?(ThisIsForm, "", KeyDetailsOfTS[ArrRow]);
		EndIf;
		ArrayOfDuplicateMessageLines.Add(StrTemplate("""%1""", AttributeRepresentation));
		
	EndDo;	
	
	SelectionFieldText = StrConcat(ArrayOfRowsOfSelectionField, "," + Chars.LF);
	ConnectionFieldText = StrConcat(ArrayOfConnectionFieldStrings, Chars.LF + "And" + " ");
	TextOfUploadField = StrConcat(ArrayOfRowsOfUploadField, ",");
	TextForReportingDuplicates =  StrConcat(ArrayOfDuplicateMessageLines, ",");
	
	QueryText =
	"SELECT 
	|	CheckTable.LineNumber,
	|	&SelectionFields1
	|INTO CheckTable
	|FROM
	|	&CheckTable AS CheckTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(CheckTable.LineNumber) AS LineNumber,
	|	COUNT(1) AS DuplicateCount,
	|	&SelectionFields1
	|INTO DuplicateLines
	|FROM
	|	CheckTable AS CheckTable
	|
	|GROUP BY 
	|	&SelectionFields1
	|
	|HAVING
	|	COUNT(1) > 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CheckTable.LineNumber,
	|	DuplicateLines.LineNumber AS FirstRow,
	|	&SelectionFields1
	|FROM
	|	CheckTable AS CheckTable
	|		INNER JOIN DuplicateLines AS DuplicateLines
	|		ON CheckTable.LineNumber <> DuplicateLines.LineNumber 
	|			AND &ConnectionFields";
	QueryText = StrReplace(QueryText, "&SelectionFields1", SelectionFieldText);
	QueryText = StrReplace(QueryText, "&ConnectionFields", ?(ConnectionFieldText = "", "TRUE", ConnectionFieldText));
	
	Query = New Query(QueryText);
	TabularSection = Object[TSName]; // TabularSection
	Query.SetParameter("CheckTable", TabularSection.Unload(RowFilter, "LineNumber," + TextOfUploadField));
	
	Selection = Query.Execute().Select();
	
	If ThisIsForm Then
		If SpecifyLineNumbers Then
			If KeyAttributes.Count() = 1 Then
				MessageTemplate = NStr("vi = 'Trong dòng %LineNumber% danh sách ""%PresentationOfTS%"" so với dòng %FirstRow% bị lặp lại giá trị ""%RepeatableValue%"" trong trường khóa.';
										|ru = 'В строке %LineNumber% списка ""%PresentationOfTS%"" по сравнению со строкой %FirstRow% повторяется значение ""%RepeatableValue%"" в ключевом поле.';
										|en = 'In line %LineNumber% of the %PresentationOfTS% list, compared to line %FirstRow% the %RepeatableValue% value is repeated in the key field.'; fa = 'In line %LineNumber% of the %PresentationOfTS% list, compared to line %FirstRow% the %RepeatableValue% value is repeated in the key field.';
										|it = 'В строке %LineNumber% списка ""%PresentationOfTS%"" по сравнению со строкой %FirstRow% повторяется значение ""%RepeatableValue%"" в ключевом поле.';
										|pl = 'W wierszu %LineNumber% listy ""%PresentationOfTS%"" w porównaniu z wierszem %FirstRow% jest powtarzana wartość ""%RepeatableValue%"" w polu kluczowym.';
										|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında, %FirstRow% satırıyla karşılaştırıldığında, anahtar alanındaki ""%RepeatableValue%"" değeri tekrarlanır.'");
			Else
				MessageTemplate = NStr("vi = 'Trong dòng %LineNumber% danh sách ""%PresentationOfTS%"" so với dòng %FirstRow% bị lặp lại tổ hợp giá trị ""%RepeatableValue%"" trong các trường khóa.';
										|ru = 'В строке %LineNumber% списка ""%PresentationOfTS%"" по сравнению со строкой %FirstRow% повторяется сочетание значений ""%RepeatableValue%"" в ключевых полях.';
										|en = 'In line %LineNumber% of the %PresentationOfTS% list, compared to line %FirstRow% the %RepeatableValue% value combination is repeated in key fields.'; fa = 'In line %LineNumber% of the %PresentationOfTS% list, compared to line %FirstRow% the %RepeatableValue% value combination is repeated in key fields.';
										|it = 'В строке %LineNumber% списка ""%PresentationOfTS%"" по сравнению со строкой %FirstRow% повторяется сочетание значений ""%RepeatableValue%"" в ключевых полях.';
										|pl = 'W wierszu %LineNumber% listy ""%PresentationOfTS%"" w porównaniu z wierszem %FirstRow% jest powtarzana kombinacja wartości ""%RepeatableValue%"" w polach kluczowych.';
										|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında, %FirstRow% satırına kıyasla anahtar alanlarda ""%RepeatableValue%"" değerlerinin bileşimi tekrarlanır.'");
			EndIf;
		Else
			If KeyAttributes.Count() = 1 Then
				MessageTemplate = NStr("vi = 'Trong danh sách ""%PresentationOfTS%"" bị lặp lại giá trị ""%RepeatableValue%"" trong trường khóa.';
										|ru = 'В списке ""%PresentationOfTS%"" повторяется значение ""%RepeatableValue%"" в ключевом поле.';
										|en = 'In the %PresentationOfTS% list, the %RepeatableValue% value is repeated in the key field.'; fa = 'In the %PresentationOfTS% list, the %RepeatableValue% value is repeated in the key field.';
										|it = 'В списке ""%PresentationOfTS%"" повторяется значение ""%RepeatableValue%"" в ключевом поле.';
										|pl = 'Na liście ""%PresentationOfTS%"" powtarza się wartość ""%RepeatableValue%"" w polu kluczowym.';
										|tr = '""%PresentationOfTS%"" listesi, anahtar alanında ""%RepeatableValue%"" değerleri tekrarlanıyor.'");
			Else
				MessageTemplate = NStr("vi = 'Trong danh sách ""%PresentationOfTS%"" bị lặp lại tổ hợp giá trị ""%RepeatableValue%"" trong các trường khóa.';
										|ru = 'В списке ""%PresentationOfTS%"" повторяется сочетание значений ""%RepeatableValue%"" в ключевых полях.';
										|en = 'In the %PresentationOfTS% list, the %RepeatableValue% value combination is repeated in key fields.'; fa = 'In the %PresentationOfTS% list, the %RepeatableValue% value combination is repeated in key fields.';
										|it = 'В списке ""%PresentationOfTS%"" повторяется сочетание значений ""%RepeatableValue%"" в ключевых полях.';
										|pl = 'Na liście ""%PresentationOfTS%"" powtarza się kombinacja wartości ""%RepeatableValue%"" w polach kluczowych.';
										|tr = '""%PresentationOfTS%"" listesi, anahtar alanlardaki %RepeatableValue% değerlerinin bileşimi tekrarlanıyor.'");
			EndIf;
		EndIf;
	Else
		If SpecifyLineNumbers Then
			If KeyAttributes.Count() = 1 Then
				MessageTemplate = NStr("vi = 'Trong dòng %LineNumber% danh sách ""%PresentationOfTS%"" so với dòng %FirstRow% bị lặp lại giá trị ""%RepeatableValue%"" trong trường %FieldsNames1%.';
										|ru = 'В строке %LineNumber% списка ""%PresentationOfTS%"" по сравнению со строкой %FirstRow% повторяется значение ""%RepeatableValue%"" в поле %FieldsNames1%.';
										|en = 'In line %LineNumber% of the ""%PresentationOfTS%"" list, the ""%RepeatableValue%"" value is repeated in field %FieldsNames1% in comparison with line %FirstRow%.'; fa = 'In line %LineNumber% of the ""%PresentationOfTS%"" list, the ""%RepeatableValue%"" value is repeated in field %FieldsNames1% in comparison with line %FirstRow%.';
										|it = 'В строке %LineNumber% списка ""%PresentationOfTS%"" по сравнению со строкой %FirstRow% повторяется значение ""%RepeatableValue%"" в поле %FieldsNames1%.';
										|pl = 'In line %LineNumber% of the ""%PresentationOfTS%"" list, the ""%RepeatableValue%"" value is repeated in field %FieldsNames1% in comparison with line %FirstRow%.';
										|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında, %FirstRow% satırıyla karşılaştırıldığında, %FieldsNames1% alanlarındaki ""%RepeatableValue%"" değeri tekrarlanıyor.'");
			Else
				MessageTemplate = NStr("vi = 'Trong dòng %LineNumber% của danh sách ""%PresentationOfTS%"" so với dòng %FirstRow% sự kết hợp của các giá trị ""%RepeatableValue%"" trong các trường %FieldsNames1% được lặp lại.';
										|ru = 'В строке %LineNumber% списка ""%PresentationOfTS%"" по сравнению со строкой %FirstRow% повторяется сочетание значений ""%RepeatableValue%"" в полях %FieldsNames1%.';
										|en = 'In line %LineNumber% of the ""%PresentationOfTS%"" list compared to line %FirstRow% the ""%RepeatableValue%"" value combination is repeated in the %FieldsNames1% fields.'; fa = 'In line %LineNumber% of the ""%PresentationOfTS%"" list compared to line %FirstRow% the ""%RepeatableValue%"" value combination is repeated in the %FieldsNames1% fields.';
										|it = 'В строке %LineNumber% списка ""%PresentationOfTS%"" по сравнению со строкой %FirstRow% повторяется сочетание значений ""%RepeatableValue%"" в полях %FieldsNames1%.';
										|pl = 'W wierszu %LineNumber% listy ""%PresentationOfTS%"" w porównaniu z wierszem %FirstRow% jest powtarzana kombinacja wartości ""%RepeatableValue%"" w polach %FieldsNames1%.';
										|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında, %FirstRow%satırına kıyasla, %FieldsNames1% alanlarındaki ""%RepeatableValue%"" değerlerinin birleşimi tekrarlanır.'");
			EndIf;
		Else
			If KeyAttributes.Count() = 1 Then
				MessageTemplate = NStr("vi = 'Trong danh sách ""%PresentationOfTS%"" giá trị lặp lại ""%RepeatableValue%"" tại trường %FieldsNames1%.';
										|ru = 'В списке ""%PresentationOfTS%"" повторяется значение ""%RepeatableValue%"" в поле %FieldsNames1%.';
										|en = 'In the ""%PresentationOfTS%"" list, the ""%RepeatableValue%"" value is repeated in field %FieldsNames1%.'; fa = 'In the ""%PresentationOfTS%"" list, the ""%RepeatableValue%"" value is repeated in field %FieldsNames1%.';
										|it = 'В списке ""%PresentationOfTS%"" повторяется значение ""%RepeatableValue%"" в поле %FieldsNames1%.';
										|pl = 'W liście ""%PresentationOfTS%"" jest powtarzana wartość ""%RepeatableValue%"" w polu %FieldsNames1%.';
										|tr = '""%PresentationOfTS%"" listesinde, %FieldsNames1% alanındaki ""%RepeatableValue%"" değeri tekrarlanıyor.'");
			Else
				MessageTemplate = NStr("vi = 'Trong danh sách ""%PresentationOfTS%"" giá trị lặp lại ""%RepeatableValue%"" tại trường %FieldsNames1%.';
										|ru = 'В списке ""%PresentationOfTS%"" повторяется сочетание значений ""%RepeatableValue%"" в полях %FieldsNames1%.';
										|en = 'In the ""%PresentationOfTS%"" list, the ""%RepeatableValue%"" value combination is repeated in fields %FieldsNames1%.'; fa = 'In the ""%PresentationOfTS%"" list, the ""%RepeatableValue%"" value combination is repeated in fields %FieldsNames1%.';
										|it = 'В списке ""%PresentationOfTS%"" повторяется сочетание значений ""%RepeatableValue%"" в полях %FieldsNames1%.';
										|pl = 'W liście ""%PresentationOfTS%"" jest powtarzana kombinacja wartości ""%RepeatableValue%"" w polach %FieldsNames1%.';
										|tr = '""%PresentationOfTS%"" listesinde, %FieldsNames1% alanlarındaki ""%RepeatableValue%"" değerlerinin bileşimi tekrarlanır.'");
			EndIf;
		EndIf;
	EndIf;
	
	While Selection.Next() Do
		
		MessageText = StrReplace(MessageTemplate, "%PresentationOfTS%", PresentationOfTS);
		MessageText = StrReplace(MessageText, "%LineNumber%", Selection.LineNumber);
		MessageText = StrReplace(MessageText, "%FirstRow%", Selection.FirstRow);
		MessageText = StrReplace(MessageText, "%FieldsNames1%", TextForReportingDuplicates);
		
		RepeatableValue = "";
		
		For Each ArrRow In KeyAttributes Do
			ValuePresentation = TrimAll(String(Selection[ArrRow]));
			If ValueIsFilled(ValuePresentation) Then
				RepeatableValue = RepeatableValue + Selection[ArrRow] + "/";
			EndIf;
		EndDo;
		
		RepeatableValue = Left(RepeatableValue, StrLen(RepeatableValue) - 1);
		
		MessageText =  StrReplace(MessageText, "%RepeatableValue%", RepeatableValue);
		
		If SpecifyLineNumbers Then
			
			LineNumber = Selection.LineNumber; // Number
			Field = CommonClientServer.PathToTabularSection(TSName, LineNumber, "LineNumber");
			
		Else
			
			Field = TSName;
			
		EndIf;
		
		Common.MessageToUser(MessageText, DataKey, Field, "Object", Cancel);
		
	EndDo;
	
EndProcedure

// Checking whether the start and end of the period are specified correctly for the specified time fence
//
// Parameters:
//  ConditionFrequency - EnumRef.RebatesFrequencies
//  DateBegin - Date - Start date
//  DateEnd - Date - End Date
//  CheckingAccrualPeriod - Boolean
// 
// Returns:
//  Structure - Check The Periods By Time Fence:
// * ThereIsViolationOfBeginning - Boolean - 
// * TextOfStartError - String - 
// * RequiredStartDate - Date - 
// * ThereIsViolationOfEnding - Boolean - 
// * TextOfEndingError - String - 
// * RequiredEndDate - Date - 
//
Function CheckPeriodsByTimeFence(ConditionFrequency, Val DateBegin, Val DateEnd, CheckingAccrualPeriod = False) Export
	
	DateEmpty = Date(1, 1, 1);
	
	ThereIsViolationOfBeginning = False;
	ThereIsViolationOfEnding = False;
	
	CheckResult = New Structure;
	CheckResult.Insert("ThereIsViolationOfBeginning", ThereIsViolationOfBeginning);
	CheckResult.Insert("TextOfStartError", "");
	CheckResult.Insert("RequiredStartDate", DateEmpty);
	CheckResult.Insert("ThereIsViolationOfEnding", ThereIsViolationOfEnding);
	CheckResult.Insert("TextOfEndingError", "");
	CheckResult.Insert("RequiredEndDate", DateEmpty);
	
	BeginningIsFull = (BegOfDay(DateBegin) <> DateEmpty);
	EndIsFilledIn = (BegOfDay(DateEnd) <> DateEmpty);
	
	If ConditionFrequency = Enums.RebatesFrequencies.Week Then
		
		RequiredStartDate = BegOfWeek(DateBegin);
		RequiredEndDate = BegOfDay(EndOfWeek(DateEnd));
		
		If BeginningIsFull
		   And RequiredStartDate <> BegOfDay(DateBegin) Then
			
			ThereIsViolationOfBeginning = True;
			MessageTemplateStartOfAction = NStr("vi = 'Đầu kỳ hiệu lực phải là đầu tuần (%1)';
												|ru = 'Начало действия должно быть началом недели (%1)';
												|en = 'The effective date must be the beginning of the week (%1)'; fa = 'The effective date must be the beginning of the week (%1)';
												|it = 'Начало действия должно быть началом недели (%1)';
												|pl = 'The effective date must be the beginning of the week (%1)';
												|tr = 'Eylemin başlangıcı haftanın başlangıcı olmalıdır (%1)'");
			MessageTemplateStartOfPeriod = NStr("vi = 'Đầu kỳ hiệu lực phải là đầu tuần (%1)';
												|ru = 'Начало периода должно быть началом недели (%1)';
												|en = 'The period start must be the beginning of the week (%1)'; fa = 'The period start must be the beginning of the week (%1)';
												|it = 'Начало периода должно быть началом недели (%1)';
												|pl = 'The period start must be the beginning of the week (%1)';
												|tr = 'Dönemin başlangıcı haftanın başlangıcı olmalıdır (%1)'");
			
		EndIf;
		
		If EndIsFilledIn
		   And RequiredEndDate <> BegOfDay(DateEnd) Then
			
			ThereIsViolationOfEnding = True;
			ExpirationMessageTemplate = NStr("vi = 'Cuối kỳ hiệu lực phải là cuối tuần (%1)';
											|ru = 'Окончание действия должно быть концом недели (%1)';
											|en = 'The expiration date must be the end of the week (%1)'; fa = 'The expiration date must be the end of the week (%1)';
											|it = 'Окончание действия должно быть концом недели (%1)';
											|pl = 'The expiration date must be the end of the week (%1)';
											|tr = 'Eylemin sonu haftanın sonu olmalıdır (%1)'");
			MessageTemplateForEndOfPeriod = NStr("vi = 'Cuối kỳ phải là cuối tuần (%1)';
												|ru = 'Окончание периода должно быть концом недели (%1)';
												|en = 'The period end must be the end of the week (%1)'; fa = 'The period end must be the end of the week (%1)';
												|it = 'Окончание периода должно быть концом недели (%1)';
												|pl = 'The period end must be the end of the week (%1)';
												|tr = 'Dönem sonu haftanın sonu olmalıdır (%1)'");
			
		EndIf;
		
	ElsIf ConditionFrequency = Enums.RebatesFrequencies.Month Then
		
		RequiredStartDate = BegOfMonth(DateBegin);
		RequiredEndDate = BegOfDay(EndOfMonth(DateEnd));
		
		If BeginningIsFull
		   And RequiredStartDate <> BegOfDay(DateBegin) Then
			
			ThereIsViolationOfBeginning = True;
			MessageTemplateStartOfAction = NStr("vi = 'Đầu kỳ phải là đầu tháng (%1)';
												|ru = 'Начало действия должно быть началом месяца (%1)';
												|en = 'The effective date must be the beginning of the month (%1)'; fa = 'The effective date must be the beginning of the month (%1)';
												|it = 'Начало действия должно быть началом месяца (%1)';
												|pl = 'The effective date must be the beginning of the month (%1)';
												|tr = 'Eylemin başlangıcı ayın başlangıcı olmalıdır (%1)'");
			MessageTemplateStartOfPeriod = NStr("vi = 'Đầu kỳ phải là đầu tháng (%1)';
												|ru = 'Начало периода должно быть началом месяца (%1)';
												|en = 'The period start must be the beginning of the month (%1)'; fa = 'The period start must be the beginning of the month (%1)';
												|it = 'Начало периода должно быть началом месяца (%1)';
												|pl = 'The period start must be the beginning of the month (%1)';
												|tr = 'Dönemin başlangıcı ayın başlangıcı olmalıdır (%1)'");
			
		EndIf;
		
		If EndIsFilledIn
		   And  RequiredEndDate <> BegOfDay(DateEnd) Then
			
			ThereIsViolationOfEnding = True;
			ExpirationMessageTemplate = NStr("vi = 'Cuối kỳ hiệu lực phải là cuối tháng (%1)';
											|ru = 'Окончание действия должно быть концом месяца (%1)';
											|en = 'The expiration date must be the end of the month (%1)'; fa = 'The expiration date must be the end of the month (%1)';
											|it = 'Окончание действия должно быть концом месяца (%1)';
											|pl = 'The expiration date must be the end of the month (%1)';
											|tr = 'Eylemin sonu ay sonu olmalıdır (%1)'");
			MessageTemplateForEndOfPeriod = NStr("vi = 'Cuối kỳ phải là cuối tháng (%1)';
												|ru = 'Окончание периода должно быть концом месяца (%1)';
												|en = 'The period end must be the end of the month (%1)'; fa = 'The period end must be the end of the month (%1)';
												|it = 'Окончание периода должно быть концом месяца (%1)';
												|pl = 'The period end must be the end of the month (%1)';
												|tr = 'Dönem sonu ay sonu olmalıdır (%1)'");
			
		EndIf;
		
	ElsIf ConditionFrequency = Enums.RebatesFrequencies.Quarter Then
		
		RequiredStartDate = BegOfQuarter(DateBegin);
		RequiredEndDate = BegOfDay(EndOfQuarter(DateEnd));
		
		If BeginningIsFull
		   And RequiredStartDate <> BegOfDay(DateBegin) Then
			
			ThereIsViolationOfBeginning = True;
			MessageTemplateStartOfAction = NStr("vi = 'Đầu kỳ hiệu lực phải là đầu quý (%1)';
												|ru = 'Начало действия должно быть началом квартала (%1)';
												|en = 'The effective date must be the beginning of the quarter (%1)'; fa = 'The effective date must be the beginning of the quarter (%1)';
												|it = 'Начало действия должно быть началом квартала (%1)';
												|pl = 'The effective date must be the beginning of the quarter (%1)';
												|tr = 'Eylemin başlangıcı çeyreğin başlangıcı olmalıdır (%1)'");
			MessageTemplateStartOfPeriod = NStr("vi = 'Đầu kỳ phải là đầu quý (%1)';
												|ru = 'Начало периода должно быть началом квартала (%1)';
												|en = 'The period start must be the beginning of the quarter (%1)'; fa = 'The period start must be the beginning of the quarter (%1)';
												|it = 'Начало периода должно быть началом квартала (%1)';
												|pl = 'The period start must be the beginning of the quarter (%1)';
												|tr = 'Dönem başlangıcı üç aylık dönemin başlangıcı olmalıdır (%1)'");
			
		EndIf;
		
		If EndIsFilledIn
		   And  RequiredEndDate <> BegOfDay(DateEnd) Then
			
			ThereIsViolationOfEnding = True;
			ExpirationMessageTemplate = NStr("vi = 'Cuối kỳ hiệu lực phải là cuối quý (%1)';
											|ru = 'Окончание действия должно быть концом квартала (%1)';
											|en = 'The expiration date must be the end of the quarter (%1)'; fa = 'The expiration date must be the end of the quarter (%1)';
											|it = 'Окончание действия должно быть концом квартала (%1)';
											|pl = 'The expiration date must be the end of the quarter (%1)';
											|tr = 'Eylemin sonu çeyrek dönemin sonu olmalıdır (%1)'");
			MessageTemplateForEndOfPeriod = NStr("vi = 'Cuối kỳ phải là cuối quý (%1)';
												|ru = 'Окончание периода должно быть концом квартала (%1)';
												|en = 'The period end must be the end of the quarter (%1)'; fa = 'The period end must be the end of the quarter (%1)';
												|it = 'Окончание периода должно быть концом квартала (%1)';
												|pl = 'The period end must be the end of the quarter (%1)';
												|tr = 'Dönem sonu çeyrek sonu olmalıdır (%1)'");
			
		EndIf;
		
	EndIf;
	
	CheckResult.RequiredStartDate = RequiredStartDate;
	CheckResult.RequiredEndDate = RequiredEndDate;
	
	CheckResult.ThereIsViolationOfBeginning = ThereIsViolationOfBeginning;
	If ThereIsViolationOfBeginning Then
		
		If CheckingAccrualPeriod Then
			StartMessageTemplate = MessageTemplateStartOfPeriod;
		Else
			StartMessageTemplate = MessageTemplateStartOfAction;
		EndIf;
		
		CheckResult.TextOfStartError = StringFunctionsClientServer.SubstituteParametersToString(
			StartMessageTemplate,
			Format(RequiredStartDate, "DLF=D;"));
		
	EndIf;
	
	CheckResult.ThereIsViolationOfEnding = ThereIsViolationOfEnding;
	If ThereIsViolationOfEnding Then
		
		If CheckingAccrualPeriod Then
			EndMessageTemplate = MessageTemplateForEndOfPeriod;
		Else
			EndMessageTemplate = ExpirationMessageTemplate;
		EndIf;
		
		CheckResult.TextOfEndingError = StringFunctionsClientServer.SubstituteParametersToString(
			EndMessageTemplate,
			Format(RequiredEndDate, "DLF=D;"));
		
	EndIf;
	
	Return CheckResult;
	
EndFunction

#Region Other

// Performs the setting of the session. Called from the session module.
//
// Parameters:
//   ParameterName  - String - name of the session parameter.
//   SpecifiedParameters - Array of String - an array of all set parameters of the session.
//
Procedure SetSessionParameters(ParameterName, SpecifiedParameters) Export
	
	SessionParameters.PostWithoutRebateBalanceCheck = False;
	
	If ParameterName = "PostWithoutRebateBalanceCheck" Then
		
		SessionParameters.PostWithoutRebateBalanceCheck = False;
		SpecifiedParameters.Add(ParameterName);
		
	EndIf;

EndProcedure

#EndRegion

#Region InterfaceImplementation

// See also updating the information base undefined.At firstfillingelements
//
// Parameters:
//  LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//  Items   - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//  TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	#Region CustomerRebates
	
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_CustomerRebatesKinds";
	Set.Ref = New UUID("a5dc0822-c1f3-46f1-aa4f-966144930cbd");
	Set.Used = GetFunctionalOption("UseCustomerRebates");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Dạng thưởng lũy kế cho khách hàng';
		|ru = 'Виды ретро-бонусов клиентов';
		|en = 'Customer rebate kinds';
		|it = 'Виды ретро-бонусов клиентов';
		|pl = 'Customer rebate kinds';
		|tr = 'Müşteri retro-bonus türleri'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_ConditionsOfCustomerRebates";
	Set.Ref = New UUID("8a733795-0f00-41e7-8e2e-8f908562db9e");
	Set.Used = GetFunctionalOption("UseCustomerRebates");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Điều kiện thưởng lũy kế cho khách hàng';
		|ru = 'Условия ретро-бонусов клиентов';
		|en = 'Conditions of customer rebates';
		|it = 'Условия ретро-бонусов клиентов';
		|pl = 'Conditions of customer rebates';
		|tr = 'Müşteri retro bonus şartları'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_DebitCustomerRebates";
	Set.Ref = New UUID("b770ef38-80ab-4ae0-bc77-f07eed4a2468");
	Set.Used = GetFunctionalOption("UseCustomerRebates");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Giảm thưởng lũy kế của khách hàng';
		|ru = 'Списания ретро-бонусов клиентов';
		|en = 'Write off customer rebates';
		|it = 'Списания ретро-бонусов клиентов';
		|pl = 'Write off customer rebates';
		|tr = 'Müşteri retro-bonusu ayrıntıları'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_AccrualOfCustomerRebates";
	Set.Ref = New UUID("ec2e9239-8e45-421e-9444-6d8695e7fd63");
	Set.Used = GetFunctionalOption("UseCustomerRebates");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Tính thưởng lũy kế cho khách hàng';
		|ru = 'Начисления ретро-бонусов клиентов';
		|en = 'Accrual of customer rebates';
		|it = 'Начисления ретро-бонусов клиентов';
		|pl = 'Accrual of customer rebates';
		|tr = 'Müşteri retro-bonus hesaplamaları'", LanguagesCodes); // @NStr-2
	
	#EndRegion
	
	#Region VendorRebates
	
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_VendorRebateKinds";
	Set.Ref = New UUID("10bd040b-2e2c-42a1-8aeb-286679ff65c1");
	Set.Used  = GetFunctionalOption("UseVendorRebates");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Dạng thưởng lũy kế của nhà cung cấp';
		|ru = 'Виды ретро-бонусов поставщиков';
		|en = 'Vendor rebate kinds';
		|it = 'Виды ретро-бонусов поставщиков';
		|pl = 'Vendor rebate kinds';
		|tr = 'Tedarikçi retro bonus türleri'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_ConditionsOfVendorRebates";
	Set.Ref = New UUID("8b5044da-952b-45a9-a41e-acc51eeff380");
	Set.Used  = GetFunctionalOption("UseVendorRebates");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Điều kiện thưởng lũy kế của nhà cung cấp';
		|ru = 'Условия ретро-бонусов поставщика';
		|en = 'Conditions of vendor rebates';
		|it = 'Условия ретро-бонусов поставщика';
		|pl = 'Conditions of vendor rebates';
		|tr = 'Tedarikçinin retro bonusu şartları'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_AccrualOfVendorRebates";
	Set.Ref = New UUID("5e2d68e4-3440-4cd3-badc-7d3fa36d40ca");
	Set.Used  = GetFunctionalOption("UseVendorRebates");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Tính thưởng lũy kế của nhà cung cấp';
		|ru = 'Начисление ретро-бонусов поставщика';
		|en = 'Accrual of vendor rebates';
		|it = 'Начисление ретро-бонусов поставщика';
		|pl = 'Accrual of vendor rebates';
		|tr = 'Tedarikçi retro bonusu tahakkuku'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_WriteOffVendorRebates";
	Set.Ref = New UUID("9a178e3f-35c3-4a06-b20c-e840c03805aa");
	Set.Used = GetFunctionalOption("UseVendorRebates");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Giảm thưởng lũy kế của nhà cung cấp';
		|ru = 'Списания ретро-бонусов поставщиков';
		|en = 'Write off vendor rebates';
		|it = 'Списания ретро-бонусов поставщиков';
		|pl = 'Write off vendor rebates';
		|tr = 'Tedarikçi retro bonusu ayrıntıları'", LanguagesCodes); // @NStr-2
	
	#EndRegion
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.Catalogs.CustomerBonusCertificateAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.VendorBonusCertificateAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ConditionsOfCustomerRebatesAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ConditionsOfVendorRebatesAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.AccrualOfCustomerRebatesAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.AccrualOfVendorRebatesAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.DebitCustomerRebatesAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.WriteOffVendorRebatesAttachedFiles, True);
	
	Lists.Insert(Metadata.Documents.ConditionsOfCustomerRebates, True);
	Lists.Insert(Metadata.Documents.ConditionsOfVendorRebates, True);
	Lists.Insert(Metadata.Documents.AccrualOfCustomerRebates, True);
	Lists.Insert(Metadata.Documents.AccrualOfVendorRebates, True);
	Lists.Insert(Metadata.Documents.DebitCustomerRebates, True);
	Lists.Insert(Metadata.Documents.WriteOffVendorRebates, True);
	Lists.Insert(Metadata.Documents.CustomerBonusCertificate, True);
	Lists.Insert(Metadata.Documents.VendorBonusCertificate, True);
	
	Lists.Insert(Metadata.InformationRegisters.CompletedConditionsOfVendorRebates, True);
	Lists.Insert(Metadata.InformationRegisters.CompletedConditionsOfVendorRebatesHistory, True);
	Lists.Insert(Metadata.InformationRegisters.CustomerRebatesTIN, True);
	Lists.Insert(Metadata.InformationRegisters.VendorRebatesTIN, True);
	Lists.Insert(Metadata.InformationRegisters.CustomerRebatesCounterparties, True);
	Lists.Insert(Metadata.InformationRegisters.VendorRebatesCounterparties, True);
	Lists.Insert(Metadata.InformationRegisters.VendorRebatesVendors, True);
	Lists.Insert(Metadata.InformationRegisters.CustomerRebatesPartnerSegments, True);
	Lists.Insert(Metadata.InformationRegisters.CustomerRebatesItemSegments, True);
	Lists.Insert(Metadata.InformationRegisters.VendorRebatesGoodsSegments, True);
	Lists.Insert(Metadata.InformationRegisters.VendorRebatesWarehouses, True);
	Lists.Insert(Metadata.InformationRegisters.CustomerRebatesItems, True);
	Lists.Insert(Metadata.InformationRegisters.VendorRebatesGoods, True);
	Lists.Insert(Metadata.InformationRegisters.CustomerRebatesItemProperties, True);
	Lists.Insert(Metadata.InformationRegisters.VendorRebatesItemProperties, True);
	Lists.Insert(Metadata.InformationRegisters.CustomerRebatesConditions, True);
	Lists.Insert(Metadata.InformationRegisters.VendorRebatesConditions, True);
	Lists.Insert(Metadata.InformationRegisters.CustomerRebatesAccrualPeriods, True);
	Lists.Insert(Metadata.InformationRegisters.CustomerRebatesContractsTermsOfSales, True);
	Lists.Insert(Metadata.InformationRegisters.RebatesCalculationScales, True);
	
	Lists.Insert(Metadata.AccumulationRegisters.CustomerRebates, True);
	Lists.Insert(Metadata.AccumulationRegisters.VendorRebates, True);
	
EndProcedure

// See ReportsOptionsOverridable.DefineObjectsWithReportCommands
Procedure DefineObjectsWithReportCommands(Objects) Export
	
	Objects.Add(Metadata.Documents.ConditionsOfCustomerRebates);
	Objects.Add(Metadata.Documents.AccrualOfCustomerRebates);
	Objects.Add(Metadata.Documents.CustomerBonusCertificate);
	Objects.Add(Metadata.Documents.VendorBonusCertificate);
	Objects.Add(Metadata.Documents.ConditionsOfVendorRebates);
	Objects.Add(Metadata.Documents.AccrualOfVendorRebates);
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	DocumentType = TypeOf(Document);
	If DocumentType = Type("DocumentObject.ConditionsOfCustomerRebates")
	 Or DocumentType = Type("DocumentObject.ConditionsOfVendorRebates") Then
		
		Parameters.ThereAreDerivedMotions = True;
		
	EndIf;
	
	If DocumentType = Type("DocumentObject.ConditionsOfCustomerRebates")
	 Or DocumentType = Type("DocumentObject.AccrualOfCustomerRebates")
	 Or DocumentType = Type("DocumentObject.DebitCustomerRebates")
	 Or DocumentType = Type("DocumentObject.CustomerBonusCertificate") Then
		
		// Posting
		If Properties.WriteMode = DocumentWriteMode.Posting Then
			
			Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.CustomerRebates);
			
		EndIf;
		
		// Control
		If Properties.WriteMode <> DocumentWriteMode.Write Then
			
			Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.CustomerRebates);
			
		EndIf;
		
	EndIf;
	
	If DocumentType  = Type("DocumentObject.AccrualOfCustomerRebates") Then
		
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.CustomerRebatesAccrualPeriods);
		
	EndIf;
	
	If DocumentType = Type("DocumentObject.ConditionsOfVendorRebates")
	 Or DocumentType = Type("DocumentObject.AccrualOfVendorRebates")
	 Or DocumentType = Type("DocumentObject.WriteOffVendorRebates")
	 Or DocumentType = Type("DocumentObject.VendorBonusCertificate") Then
		
		// Posting
		If Properties.WriteMode = DocumentWriteMode.Posting Then
			
			Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.VendorRebates);
			
		EndIf;
		
		// Control
		If Properties.WriteMode <> DocumentWriteMode.Write Then
			
			Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.VendorRebates);
			
		EndIf;
		
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map of KeyAndValue - Contains the texts of the cancellation requests, where:
// 		* Key - String - full name of the register.
// 		* Value - String - query text.
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	QueriesTexts = New Map();
	
	Return QueriesTexts;
	
EndFunction

// Occurs before writing the registers the document.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - temporary table Manager
//								used for storing register change control tables.
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure BeforeRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	Return;
	
EndProcedure

// Occurs after the document registers are recorded
//
// Parameters:
//  Document - DocumentObject.ConditionsOfCustomerRebates, DocumentObject.ConditionsOfVendorRebates - recordable document
//  TempTablesManager - TempTablesManager - temporary table Manager
//								used for storing register change control tables.
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure AfterRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	DocumentProperties = DocumentsPosting.DocumentProperties(Document);
	
	RegisterNames = New Array; // Array of String
	
	DocumentType = TypeOf(Document);
	If DocumentType = Type("DocumentObject.ConditionsOfCustomerRebates") Then
		
		RegisterNames.Add("CustomerRebatesConditions");
		RegisterNames.Add("CustomerRebatesCounterparties");
		RegisterNames.Add("CustomerRebatesTIN");
		RegisterNames.Add("CustomerRebatesContractsTermsOfSales");
		RegisterNames.Add("CustomerRebatesPartnerSegments");
		RegisterNames.Add("CustomerRebatesItems");
		RegisterNames.Add("CustomerRebatesItemProperties");
		RegisterNames.Add("CustomerRebatesItemSegments");
		RegisterNames.Add("RebatesCalculationScales");
		
	ElsIf DocumentType = Type("DocumentObject.ConditionsOfVendorRebates") Then
		
		RegisterNames.Add("VendorRebatesConditions");
		RegisterNames.Add("VendorRebatesTIN");
		RegisterNames.Add("VendorRebatesGoods");
		RegisterNames.Add("VendorRebatesItemProperties");
		RegisterNames.Add("VendorRebatesGoodsSegments");
		RegisterNames.Add("VendorRebatesCounterparties");
		RegisterNames.Add("VendorRebatesVendors");
		RegisterNames.Add("VendorRebatesWarehouses");
		RegisterNames.Add("RebatesCalculationScales");
		
	Else
		
		ExceptionPattern = NStr("vi = 'Đã truyền %1 kiểu không xác định của chứng từ vào phương thức %2';
								|ru = 'В метод %1 передан неизвестный тип документа %2';
								|en = 'An unknown document type %2 was passed to method %1'; fa = 'An unknown document type %2 was passed to method %1';
								|it = 'В метод %1 передан неизвестный тип документа %2';
								|pl = 'An unknown document type %2 was passed to method %1';
								|tr = '%1 yöntemiyle bilinmeyen %2 belge türüne aktarıldı'");
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			ExceptionPattern,
			"RebatesServer.AfterRecordingDocumentRegisteredRecords",
			String(DocumentType));
		Raise ExceptionText;
		
	EndIf;
	
	SourceDocument_ = ?(Document.CorrectedDocument.IsEmpty(), Document.Ref, Document.CorrectedDocument);
	
	If DocumentProperties.WriteMode = DocumentWriteMode.UndoPosting Then
		
		If Document.CorrectedDocument.IsEmpty() Then
			
			ClearUpToDateDataRegisters(Document.Ref, RegisterNames);
			
		Else
			
			Selection = UpToDateDocumentOfRebatesTermsAndConditions(Document);
			If Selection.Next() Then
				
				ActualDocument = Selection.Ref; // DocumentRef.TermsOfRebatesForBuyers
				CreateRegistersOfUpToDateData(ActualDocument, SourceDocument_, RegisterNames);
				
			Else
				
				// Only the original document itself remains
				CreateRegistersOfUpToDateData(SourceDocument_, SourceDocument_, RegisterNames);
				
			EndIf;
			
		EndIf;
		
	Else
		
		If Document.Status = Enums.RebatesDocumentStatuses.Approved
		 Or Document.CorrectedDocument.IsEmpty() Then
			
			CreateRegistersOfUpToDateData(Document.Ref, SourceDocument_, RegisterNames);
			
		Else
			
			Selection = UpToDateDocumentOfRebatesTermsAndConditions(Document);
			
			If Selection.Next() Then
				
				ActualDocument = Selection.Ref; // DocumentRef.TermsOfRebatesForBuyers
				CreateRegistersOfUpToDateData(ActualDocument, SourceDocument_, RegisterNames);
				
			Else
				
				// Only the original document itself remains
				CreateRegistersOfUpToDateData(SourceDocument_, SourceDocument_, RegisterNames);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// The procedure of formation of movements to the slave control registers range.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "CustomerRebates");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "CustomerRebatesAccrualPeriods");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "VendorRebates");
	
EndProcedure

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map of KeyAndValue:
//		* Key - String - The name of the temporary register change table.
//		* Value - String - query text.
//
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export
	
	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList of String - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	InitializationOfChangeControlCustomerRebates(Query, QueryTexts, Document);
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes:
//   * ErrorsInDebitingBonusAmounts - ValueTable:
//     ** Organization - CatalogRef.Companies
//     ** Counterparty - CatalogRef.Counterparties
//     ** Partner - CatalogRef.Partners
//     ** BeginOfPeriod - Date
//     ** PeriodEnding - Date
//     ** TermDocument - DocumentRef.ConditionsOfCustomerRebates
//     ** Currency - CatalogRef.Currencies
//     ** AmountBonusBalance - DefinedType.MonetaryAmountPositiveNegative
//     ** ControlAsOfDocumentDate - Boolean
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	ChangeControlCustomerRebates(ControlResults, Document, Cancel);
	
EndProcedure

#EndRegion

#Region AccessManagement

// See AccessManagementOverridable.OnFillSuppliedAccessGroupProfiles
//
Procedure AddSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate) Export
	
	AddResponsibleProfileRebateKindOfCustomers(ProfilesDetails, ParametersOfUpdate);
	AddProfileManagerOfCustomerRebates(ProfilesDetails, ParametersOfUpdate);
	AddParticipantProfileToAgreeOnTermsOfCustomerRebates(ProfilesDetails, ParametersOfUpdate);
	AddProfileResponsibleForCustomerBonusCertificatesAdditional(ProfilesDetails, ParametersOfUpdate);
	
	AddResponsibleProfileRebateKindOfSuppliers(ProfilesDetails, ParametersOfUpdate);
	AddProfileManagerRebatesSuppliers(ProfilesDetails, ParametersOfUpdate);
	AddProfileOfMemberOfAgreementOfTermsOfRebatesOfSuppliers(ProfilesDetails, ParametersOfUpdate);
	AddProfileResponsibleForSupplierPremiumCertificatesAdditional(ProfilesDetails, ParametersOfUpdate);
	
	AddProfileRightToDisableControlOfBalancesOfRebatesAdditional(ProfilesDetails, ParametersOfUpdate);
	
EndProcedure

#EndRegion

#Region BatchProcessingOfStrings

// See BatchProcessingOfTablePartServer.WhenAddingCollectionLineHandlers
Procedure WhenAddingCollectionLineHandlers(StringHandlers) Export
	
	StringHandlers.Add(
		"FillInAgreementAttributeInTSLine",
		"RebatesServer.ProcessingOfLinesFillInSignOfAgreementInLineTS");
	
	StringHandlers.Add(
		"FillInCurrencyIndicationForRebatesOfSuppliers",
		"RebatesServer.ProcessingStringsToFillInPropertiesOfRebatesSuppliers");
	
	StringHandlers.Add(
		"FillInCurrencyOfVendorSRebates",
		"RebatesServer.ProcessingStringsToFillInPropertiesOfRebatesSuppliers");
	
EndProcedure

// Parameters:
//	CurrentRow - Structure:
//		* Terms - CatalogRef.TermsOfSale
//		* ThisIsModelAgreement - Boolean
//	StructureOfActions - See BatchProcessingOfTablePartClient.ProcessTSString.StructureOfActions
//	Cached_Values - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure ProcessingOfLinesFillInSignOfAgreementInLineTS(CurrentRow, StructureOfActions, Cached_Values = Undefined) Export
	
	Var NameOfAgreementField; // String
	
	StructureOfActions.Property("FillInAgreementAttributeInTSLine", NameOfAgreementField);
	
	DataForProcessing = BatchProcessingOfTablePartServer.DataForStringProcessing(
		"SignsOfAgreements", Cached_Values); 
	
	If DataForProcessing <> Undefined Then
		
		ReceivedData = DataForProcessing[0].ThisIsModelAgreement; // Boolean
		CurrentRow.ThisIsModelAgreement = ReceivedData;
		
		MeaningOfAgreement = CurrentRow[NameOfAgreementField]; // CatalogRef.TermsOfSale
		Cached_Values.SignsOfAgreements[MeaningOfAgreement] = CurrentRow.ThisIsModelAgreement;
		
	EndIf;
	
EndProcedure

// Parameters:
//	CurrentRow - Structure:
//		* TermDocument - DocumentRef.ConditionsOfVendorRebates
//		* CurrencyIsDeterminedByCondition - Boolean
//		* BonusCurrency - CatalogRef.Currencies
//	StructureOfActions - See BatchProcessingOfTablePartClient.ProcessTSString.StructureOfActions
//	Cached_Values - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure ProcessingStringsToFillInPropertiesOfRebatesSuppliers(CurrentRow, StructureOfActions, Cached_Values = Undefined) Export
	
	DataForProcessing = BatchProcessingOfTablePartServer.DataForStringProcessing(
		"PropertiesOfRebatesSuppliers", Cached_Values); 
	
	If DataForProcessing = Undefined Then
		Return;
	EndIf;
	
	For Each FillingAction In StructureOfActions Do
		
		ActionIsRequired = BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			FillingAction.Key,
			StructureOfActions,
			Cached_Values); 
		
		If Not ActionIsRequired  Then 
			StructureOfActions.Delete(FillingAction.Key);
		EndIf;
		
	EndDo;
	
	AdditionalInformation_3 = BatchProcessingOfTablePartServer.DescriptionOfAdditionalInformation(StructureOfActions);
	
	FillPropertyValues(
		CurrentRow,
		DataForProcessing[0],
		AdditionalInformation_3.DetailsOfFillingInForm);
	
EndProcedure

// Parameters:
//  Actions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  Cached_Values - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure AddQueryTextsOfDataSources(Actions, QueryDetails, Cached_Values) Export
	
	AddAgreementAttributeToQueryTextInTSLine(Actions, QueryDetails, Cached_Values);
	AddQueryTextToRebatePropertiesOfSuppliersVBonuses(Actions, QueryDetails, Cached_Values);
	
EndProcedure

#EndRegion

#Region WorkingWithForms

// Parameters:
//  Form - ClientApplicationForm - List form:
//   * List - DynamicList
//
Procedure SetStatusFormalization(Form) Export
	
	ListOfConditionalAppearance = Form.List.ConditionalAppearance;
	
	#Region AwaitingApproval
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Đánh dấu đậm trạng thái ""Cần thống nhất""';
							|ru = 'Выделение шрифтом статуса ""На согласовании""';
							|en = 'Highlight the ""On approval"" status with font'; fa = 'Highlight the ""On approval"" status with font';
							|it = 'Выделение шрифтом статуса ""На согласовании""';
							|pl = 'Highlight the ""On approval"" status with font';
							|tr = '“Onay bekliyor” durumunun yazı tipiyle vurgulanması'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Status");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.RebatesDocumentStatuses.AwaitingApproval;
	
	Item.Appearance.SetParameterValue("Font", StyleFonts.BoldFont);
	#EndRegion
	
	#Region Approved
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Đánh dấu màu trạng thái ""Đã thống nhất""';
							|ru = 'Выделение цветом статуса ""Согласован""';
							|en = 'Highlight the ""Approved"" status'; fa = 'Highlight the ""Approved"" status';
							|it = 'Выделение цветом статуса ""Согласован""';
							|pl = 'Highlight the ""Approved"" status';
							|tr = '“Kabul Edildi” durumunun vurgu rengi'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Status");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.RebatesDocumentStatuses.Approved;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SuccessResultColor);
	#EndRegion
	
	#Region NotApproved
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Đánh dấu màu trạng thái ""Không thống nhất""';
							|ru = 'Выделение цветом статуса ""Не согласован""';
							|en = 'Highlight the ""Not approved"" status'; fa = 'Highlight the ""Not approved"" status';
							|it = 'Выделение цветом статуса ""Не согласован""';
							|pl = 'Highlight the ""Not approved"" status';
							|tr = '“Kabul Edilmedi” durumunun vurgu rengi'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Status");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.RebatesDocumentStatuses.NotApproved;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ResultIssueColor);
	#EndRegion
	
EndProcedure

// Parameters:
//  Form - ClientApplicationForm - List form:
//   * List - DynamicList
//
Procedure SetRegistrationOfMultiCurrencyDocuments(Form) Export
	
	ListOfConditionalAppearance = Form.List.ConditionalAppearance;
	
	#Region Currency
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Ẩn tiền tệ của chứng từ đa tiền tệ';
							|ru = 'Скрытие валюты мультивалютных документов';
							|en = 'Hiding the currency of multicurrency documents'; fa = 'Hiding the currency of multicurrency documents';
							|it = 'Скрытие валюты мультивалютных документов';
							|pl = 'Hiding the currency of multicurrency documents';
							|tr = 'Çok para birimli belgede para birimlerinin saklanması'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Currency");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MulticurrencyDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", "<..>");
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Center);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	#EndRegion
	
	#Region DocumentAmount
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Nội dung của chứng từ đa tiền tệ';
							|ru = 'Текст мультивалютных документов';
							|en = 'Text of multicurrency documents'; fa = 'Text of multicurrency documents';
							|it = 'Текст мультивалютных документов';
							|pl = 'Text of multicurrency documents';
							|tr = 'Çok para birimli belge metni'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DocumentAmount");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MulticurrencyDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", "<..>");
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Center);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	#EndRegion
	
EndProcedure

// Set the headings of the scenery fixing segments.
// 
// Parameters:
//  Form - See Document.ConditionsOfCustomerRebates.Form.DocumentForm
//  	  - See Document.ConditionsOfVendorRebates.Form.DocumentForm
//
Procedure SetSceneryTitlesWithHyperlinks(Form) Export
	
	If Form.ThereAreAccruals Then
		
		TextCancelApproval = NStr("vi = 'Đã tính toán, cấm hủy thống nhất';
									|ru = 'Созданы начисления, отмена согласования запрещена';
									|en = 'Accruals are created. Cannot cancel the approval'; fa = 'Accruals are created. Cannot cancel the approval';
									|it = 'Созданы начисления, отмена согласования запрещена';
									|pl = 'Accruals are created. Cannot cancel the approval';
									|tr = 'Tahakkuklar oluşturuldu, onayın iptali yasaklandı'");
		
	Else
		
		TemplateCancelApproval = NStr("vi = '<a href=""%1"">Hủy thống nhất</a>';
										|ru = '<a href=""%1"">Отменить согласование</a>';
										|en = '<a href=""%1"">Cancel approval</a>'; fa = '<a href=""%1"">Cancel approval</a>';
										|it = '<a href=""%1"">Отменить согласование</a>';
										|pl = '<a href=""%1"">Cancel approval</a>';
										|tr = '<a href=""%1"">Anlaşmayı iptal et</a>'");
		TextCancelApproval = StringFunctionsClientServer.SubstituteParametersToString(
			TemplateCancelApproval, "CancelApproval");
		
	EndIf;
	
	If Form.ThereIsAdjustmentOnApproval Then
		
		FixText = NStr("vi = 'Đã nhập điều chỉnh có trạng thái ""Cần thống nhất"", cấm ghi nhận thành phần chứng từ';
						|ru = 'Введена корректировка в статусе ""На согласовании"", фиксация состава документа запрещена';
						|en = 'Adjustment is entered in the ""Pending approval"" status. Cannot record the document'; fa = 'Adjustment is entered in the ""Pending approval"" status. Cannot record the document';
						|it = 'Adjustment is entered in the ""Pending approval"" status. Cannot record the document';
						|pl = 'Adjustment is entered in the ""Pending approval"" status. Cannot record the document';
						|tr = '""Onay bekliyor"" durumuna düzeltme yapıldı, belgenin içeriğinin sabitlenmesi yasaktır'");
		
	Else
		
		FixTemplate = NStr("vi = 'Chưa ghi nhận thành phần chứng từ. <a href=""%1"">Ghi nhận</a>.';
							|ru = 'Состав документа не зафиксирован. <a href=""%1"">Зафиксировать</a>.';
							|en = 'The document content is not recorded. <a href=""%1"">Record</a>.'; fa = 'The document content is not recorded. <a href=""%1"">Record</a>.';
							|it = 'The document content is not recorded. <a href=""%1"">Record</a>.';
							|pl = 'The document content is not recorded. <a href=""%1"">Record</a>.';
							|tr = 'Belgenin içeriği sabitlenmedi. <a href=""%1"">Sabitle</a>.'");
		FixText = StringFunctionsClientServer.SubstituteParametersToString(
			FixTemplate, "Commit");
		
	EndIf;
	
	If Form.ThereAreAccruals Then
		
		TextCancel = NStr("vi = 'Đã tạo các khoản tính, cấm hủy ghi nhận thành phần chứng từ';
							|ru = 'Созданы начисления, отмена фиксации состава документа запрещена';
							|en = 'Accruals are created. Cannot cancel the document recording'; fa = 'Accruals are created. Cannot cancel the document recording';
							|it = 'Accruals are created. Cannot cancel the document recording';
							|pl = 'Accruals are created. Cannot cancel the document recording';
							|tr = 'Tahakkuklar oluşturuldu, belge içeriğinin sabitlenmesinin iptali yasaktır'");
		
	Else
		
		UndoCommitTemplate = NStr("vi = 'Đã ghi nhận thành phần chứng từ. <a href=""%1"">Hủy ghi nhận</a>.';
									|ru = 'Состав документа зафиксирован. <a href=""%1"">Отменить фиксацию</a>.';
									|en = 'The document content is recorded. <a href=""%1"">Cancel recording</a>.'; fa = 'The document content is recorded. <a href=""%1"">Cancel recording</a>.';
									|it = 'The document content is recorded. <a href=""%1"">Cancel recording</a>.';
									|pl = 'The document content is recorded. <a href=""%1"">Cancel recording</a>.';
									|tr = 'Belgenin içeriği sabitlendi. <a href=""%1"">Sabitlemeyi iptal et</a>.'");
		TextCancel = StringFunctionsClientServer.SubstituteParametersToString(
			UndoCommitTemplate, "CancelCommit");
		
	EndIf;
	
	Form.Items.DecorationFixComposition.Title = StringFunctions.FormattedString(FixText);
	Form.Items.DecorationIsToCancelFixationOfComposition.Title = StringFunctions.FormattedString(TextCancel);
	Form.Items.DecorationCancelApproval.Title = StringFunctions.FormattedString(TextCancelApproval);
	
EndProcedure

// Parameters:
//  Form - See Catalog.CustomerRebatesKinds.Form.ListForm
//  	  - See Catalog.CustomerRebatesKinds.Form.ChoiceForm
//  	  - See Catalog.VendorRebateKinds.Form.ListForm
//  	  - See Catalog.VendorRebateKinds.Form.ChoiceForm
//	FieldsNames - Array of String - 
//
Procedure SetConditionalAppearanceOfViewListWithoutCalculation(Form, FieldsNames) Export
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	For Each FieldName In FieldsNames Do
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FieldName);
		
	EndDo;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.WithoutCalculation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

// Parameters:
//  Form - See Catalog.CustomerRebatesKinds.Form.ListForm
//  	  - See Catalog.CustomerRebatesKinds.Form.ChoiceForm
//  	  - See Catalog.VendorRebateKinds.Form.ListForm
//  	  - See Catalog.VendorRebateKinds.Form.ChoiceForm
//	FieldsNames - Array of String - 
//
Procedure SetConditionalAppearanceOfListOfTypeIndicatorOfGoodsNotUsed(Form, FieldsNames) Export
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	For Each FieldName In FieldsNames Do
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FieldName);
		
	EndDo;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.GoodsIndicator");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TargetSalesIndicatorsOfRebatesByGoods.NotUsed;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance
//
Procedure SetDesignOfCalculationScaleTable(ConditionalAppearance) Export
	
	SetDesignCalculationScaleRangeFrom(ConditionalAppearance);
	SetDesignCalculationScaleBonusPercentage(ConditionalAppearance);
	
EndProcedure

// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance
//  TableName - String
//
Procedure SetTableLayoutFieldNumberPlan(ConditionalAppearance, TableName) Export
	
	// Feature: the field can be separately blocked by the source line in the Set the formationexciting Product lines() method
	
	FieldName = TableName + "CountPlan";
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldName);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GoodsIndicator");
	ItemFilter.RightValue = Enums.TargetSalesIndicatorsOfRebatesByGoods.Count;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CalculationScaleType");
	ItemFilter.RightValue = 1; // By Ranges
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance
//  TableName - String
//
Procedure SetTableLayoutPercentageField(ConditionalAppearance, TableName) Export
	
	// Feature: the field can be separately blocked by the source line in the method of the form of the object to set the form of the original product lines()
	
	FieldName = TableName + "Percent";
	PathToField = "Object." + TableName + ".Percent";
	
	#Region RequiredFilling
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldName);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GoodsIndicator");
	ItemFilter.RightValue = Enums.TargetSalesIndicatorsOfRebatesByGoods.Count;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CalculationScaleType");
	ItemFilter.RightValue = 1; // By Ranges
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	#Region EmptyValue
		Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldName);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GoodsIndicator");
	ItemFilter.RightValue = Enums.TargetSalesIndicatorsOfRebatesByGoods.Count;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CalculationScaleType");
	ItemFilter.RightValue = 1; // By Ranges
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToField);
	ItemFilter.RightValue = 0;
	
	StringZero = NStr("vi = '<không>';
						|ru = '<нет>';
						|en = '<no>'; fa = '<خیر>';
						|it = '<no>';
						|pl = '<no>';
						|tr = '<hayır>'");
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", StringZero);
	#EndRegion
	
EndProcedure

// Parameters:
//  Form - ClientApplicationForm - Contains this form
//  ThereIsTypeOfBonus - Boolean - Indicates whether there is a bonus type in the form object
//
Procedure SetLayoutOfItemsTableCharacteristics(Form, ThereIsTypeOfBonus = False) Export
	
	If Not GetFunctionalOption("UseItemVariants") Then
		Return;
	EndIf;
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(Form);
	ConditionalAppearance = Form.ConditionalAppearance;
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("GoodsCharacteristic");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemVariantsAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	If ThereIsTypeOfBonus Then
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.BonusType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = Enums.VendorRebateTypes.Balance;
		
	EndIf;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ValueOfPredefinedText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Tất cả>';
													|ru = '<Все>';
													|en = '<All>'; fa = '<همه>';
													|it = '<All>';
													|pl = '<All>';
													|tr = '<Tümü>'"));
	
EndProcedure

// Returns:
//  Structure - New correction design parameters:
// * SourceStringFields - Array of String - 
// * FieldsBeforeChanges - Array of String -
//
Function NewParametersForDesignOfSourceLines() Export
	
	Result = New Structure;
	Result.Insert("SourceStringFields", New Array);
	Result.Insert("FieldsBeforeChanges", New Array);
	
	Return Result;
	
EndFunction

// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance -
//  FormTable - FormTable - form table
//  Parameters - See RebatesServer.NewParametersForDesignOfSourceLines
// 
Procedure ArrangeFieldsAccordingToOriginalLines(ConditionalAppearance, FormTable, Parameters) Export
	
	KTCHPath = FormTable.DataPath;
	PathToOriginalString = KTCHPath + ".InitialString";
	
	#Region DataOfSourceString
	SourceStringFields = Parameters.SourceStringFields;
	If SourceStringFields.Count() > 0 Then
		
		Item = ConditionalAppearance.Items.Add();
		
		For Each FieldName In SourceStringFields Do
			
			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(FieldName);
			
		EndDo;
		
		For Each FieldName In Parameters.FieldsBeforeChanges Do
			
			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(FieldName);
			
		EndDo;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(PathToOriginalString);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("ReadOnly", True);
		Item.Appearance.SetParameterValue("Font", StyleFonts.BoldFont);
		
	EndIf;
	#EndRegion
	
	#Region FieldsBeforeChanges
	If Parameters.FieldsBeforeChanges.Count() > 0 Then
		
		Item = ConditionalAppearance.Items.Add();
		
		For Each FieldName In Parameters.FieldsBeforeChanges Do
			
			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(FieldName);
			
		EndDo;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(PathToOriginalString);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		Item.Appearance.SetParameterValue("Text", "-");
		Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Center);
		
	EndIf;
	#EndRegion
	
	DesignOfCancellationFlag(ConditionalAppearance, FormTable);
	
EndProcedure

// Parameters:
//  Items - FormAllItems
//  ConditionalAppearance - DataCompositionConditionalAppearance -
//
Procedure SetLayoutOfSourceRowsOfItemPropertiesTable(Items, ConditionalAppearance) Export
	
	DesignParameters = NewParametersForDesignOfSourceLines();
	TableName = "ProductProperties_";
	
	FieldValueProperty = TableName + "PropertyValue";
	NumberFieldPlan = TableName + "CountPlan";
	BasePriceField = TableName + "BasePrice";
	PercentageField = TableName + "Percent";
	
	DesignParameters.SourceStringFields.Add(FieldValueProperty);
	DesignParameters.SourceStringFields.Add(NumberFieldPlan);
	DesignParameters.SourceStringFields.Add(BasePriceField);
	DesignParameters.SourceStringFields.Add(PercentageField);
	
	StartOfActionBeforeChangesField = TableName + "StartDateBeforeChange";
	EndOfActionBeforeChangesField = TableName + "EndDateBeforeChange";
	
	DesignParameters.FieldsBeforeChanges.Add(StartOfActionBeforeChangesField);
	DesignParameters.FieldsBeforeChanges.Add(EndOfActionBeforeChangesField);
	
	ArrangeFieldsAccordingToOriginalLines(
		ConditionalAppearance,
		Items[TableName],
		DesignParameters);
	
EndProcedure

// Parameters:
//  Table Name - String -
//	Settings - ValueTable - table with columns:
//		* Fields - Array of String - fields for which display settings are defined
//		* Condition - DataCompositionFilter - terms of use settings
//		* Properties - Structure - property names and values 
//
Procedure ConfiguringItemPropertiesFieldQuantityPlan(Settings) Export
	
	FieldName = "ProductProperties_.CountPlan";
	ListCompositions = Enums.RebatesLists;
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	Item = Settings.Add();
	
	Item.Fields.Add(FieldName);
	
	OrGroup = NewFiltersGroup(Item.Condition);
	FinancialReportingServer.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.ExceptForSelectedOnes);
	
	AndGroup = NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	FinancialReportingServer.NewFilter(AndGroup, "FilterOfProducts_", ListCompositions.Selected_);
	
	Indicators = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	Indicators.Add(GoodsIndicators.NotUsed);
	Indicators.Add(GoodsIndicators.Sum);
	
	FinancialReportingServer.NewFilter(
		AndGroup, "More.GoodsIndicator", Indicators,, DataCompositionComparisonType.InList);
	
	Item.Properties.Insert("Visible", False);
	
EndProcedure

// Parameters:
//  Table Name - String -
//	Settings - ValueTable - table with columns:
//		* Fields - Array of String - fields for which display settings are defined
//		* Condition - DataCompositionFilter - terms of use settings
//		* Properties - Structure - property names and values 
//
Procedure SettingUpDecorationPropertiesFieldThereAreCharges(Settings) Export
	
	ListCompositions = Enums.RebatesLists;
	SalesFigures = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	ContentOfGoods = Enums.RebatesItems;
	
	Item = Settings.Add();
	
	Item.Fields.Add("DecorationOfPropertyHasAccruals");
	
	OrGroup = NewFiltersGroup(Item.Condition);
	FinancialReportingServer.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.ExceptForSelectedOnes);
	
	ExclIndicators = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ExclIndicators.Add(SalesFigures.QuantityTotal);
	ExclIndicators.Add(SalesFigures.BatchOffer);
	FinancialReportingServer.NewFilter(
		OrGroup, "More.GoodsIndicator", ExclIndicators,, DataCompositionComparisonType.InList);
	FinancialReportingServer.NewFilter(Item.Condition, "More.ThereAreAccruals", True);
	FinancialReportingServer.NewFilter(
		Item.Condition,
		"More.ContentOfGoods",
		ContentOfGoods.ProductItemProperty);
	
	Item.Properties.Insert("Visible", True);
	
EndProcedure

// Parameters:
//  Table Name - String -
//	Settings - ValueTable - table with columns:
//		* Fields - Array of String - fields for which display settings are defined
//		* Condition - DataCompositionFilter - terms of use settings
//		* Properties - Structure - property names and values 
//
Procedure SettingUpItemPropertyFieldPresentation(Settings) Export
	
	ContentOfGoods = Enums.RebatesItems;
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("ProductItemPropertyPresentation");
	
	OrGroup = NewFiltersGroup(Item.Condition);
	FinancialReportingServer.NewFilter(
		OrGroup,
		"RebateKind",
		Catalogs.CustomerRebatesKinds.EmptyRef());
	FinancialReportingServer.NewFilter(OrGroup, "WithoutCalculation", True);
	FinancialReportingServer.NewFilter(
		OrGroup, 
		"More.ContentOfGoods",
		ContentOfGoods.ProductItemProperty,
		,
		DataCompositionComparisonType.NotEqual);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
EndProcedure

#EndRegion

#Region Other

// Document title.
// 
// Parameters:
//  Document - DocumentRef.ConditionsOfCustomerRebates, DocumentRef.ConditionsOfVendorRebates, DocumentRef.AccrualOfCustomerRebates, DocumentRef.AccrualOfVendorRebates, DocumentRef.DebitCustomerRebates, DocumentRef.WriteOffVendorRebates - document being processed
//  DocumentNumber - String - document number
//  DocumentDate - Date - Document date
//  Patch - Boolean, Undefined - A sign of a corrective document
// 
// Returns:
//  String - presentation of the document
//
Function DocumentTitle(Document, DocumentNumber, DocumentDate, Patch = Undefined) Export
	
	If Patch = Null Then
		Return "";
	EndIf;
	
	// When expanding the types, add the condition below
	AllowedTypes = New Array; // Array of Type
	AllowedTypes.Add(Type("DocumentRef.ConditionsOfCustomerRebates"));
	AllowedTypes.Add(Type("DocumentRef.AccrualOfCustomerRebates"));
	AllowedTypes.Add(Type("DocumentRef.DebitCustomerRebates"));
	AllowedTypes.Add(Type("DocumentRef.ConditionsOfVendorRebates"));
	AllowedTypes.Add(Type("DocumentRef.AccrualOfVendorRebates"));
	AllowedTypes.Add(Type("DocumentRef.WriteOffVendorRebates"));
	
	DocumentType = TypeOf(Document);
	MethodName = "RebatesServer.DocumentTitle";
	TypeErrorTemplate = NStr("vi = 'Đã truyền kiểu chưa được xử lý %1';
							|ru = 'Передан необрабатываемый тип %1';
							|en = 'Unprocessable type %1 passed'; fa = 'Unprocessable type %1 passed';
							|it = 'Передан необрабатываемый тип %1';
							|pl = 'Unprocessable type %1 passed';
							|tr = 'İşlenmemiş %1 türü girilmiş'");
	TypeErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		TypeErrorTemplate, String(DocumentType));
	
	CommonClientServer.Validate(
		AllowedTypes.Find(DocumentType) <> Undefined,
		TypeErrorText,
		MethodName);
	
	// It is performed explicitly to speed up processing in the Presentation handler. Getting the manager by reference is not used
	If DocumentType = Type("DocumentRef.ConditionsOfCustomerRebates") Then
		DocumentHeaderTemplate = Documents.ConditionsOfCustomerRebates.DocumentHeaderTemplate(Patch);
	ElsIf DocumentType = Type("DocumentRef.AccrualOfCustomerRebates") Then
		DocumentHeaderTemplate = Documents.AccrualOfCustomerRebates.DocumentHeaderTemplate();
	ElsIf DocumentType = Type("DocumentRef.DebitCustomerRebates") Then
		DocumentHeaderTemplate = Documents.DebitCustomerRebates.DocumentHeaderTemplate();
	ElsIf DocumentType = Type("DocumentRef.ConditionsOfVendorRebates") Then
		DocumentHeaderTemplate = Documents.ConditionsOfVendorRebates.DocumentHeaderTemplate(Patch);
	ElsIf DocumentType = Type("DocumentRef.AccrualOfVendorRebates") Then
		DocumentHeaderTemplate = Documents.AccrualOfVendorRebates.DocumentHeaderTemplate();
	ElsIf DocumentType = Type("DocumentRef.WriteOffVendorRebates") Then
		DocumentHeaderTemplate = Documents.WriteOffVendorRebates.DocumentHeaderTemplate();
	Else
		
		ExceptionPattern = NStr("vi = 'Để nhận khuôn mẫu, tiêu đề chứng từ trong phương thức %1 chưa xác định phương thức nhận cho kiểu %2.';
								|ru = 'Для получения шаблона заголовка документа в методе %1 не определен метод получения для типа %2.';
								|en = 'To obtain the document header template, %1 method does not define a receiving method for the %2 type.'; fa = 'To obtain the document header template, %1 method does not define a receiving method for the %2 type.';
								|it = 'Для получения шаблона заголовка документа в методе %1 не определен метод получения для типа %2.';
								|pl = 'To obtain the document header template, %1 method does not define a receiving method for the %2 type.';
								|tr = 'Для получения шаблона заголовка документа в методе %1 не определен метод получения для типа %2.'");
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			ExceptionPattern,
			MethodName,
			String(DocumentType));
		Raise ExceptionText;
		
	EndIf;
	
	EndOfTitle = "";
	
	If ValueIsFilled(Document) Then
		
		TemplateEndingOfTitle = NStr("vi = '%1 ngày %2';
									|ru = '%1 от %2';
									|en = '%1 from %2'; fa = '%1 from %2';
									|it = '%1 от %2';
									|pl = '%1 z dn. %2';
									|tr = '%2 itibarıyla %1'");
		If DocumentType =  Type("DocumentRef.ConditionsOfCustomerRebates")
		 Or DocumentType =  Type("DocumentRef.ConditionsOfVendorRebates") Then
			
			EndOfTitle = StringFunctionsClientServer.SubstituteParametersToString(
				TemplateEndingOfTitle, DocumentNumber, Format(DocumentDate, "DLF=D;"));
			
		Else
			
			EndOfTitle = StringFunctionsClientServer.SubstituteParametersToString(
				TemplateEndingOfTitle, DocumentNumber, String(DocumentDate));
			
		EndIf;
		
	Else
		
		EndOfTitle = NStr("vi = '(tạo mới)';
							|ru = '(создание)';
							|en = '(create)'; fa = '(create)';
							|it = '(создание)';
							|pl = '(utworzenie)';
							|tr = '(oluşturma)'");
		
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		DocumentHeaderTemplate, EndOfTitle);
	
EndFunction

// Determines the maximum end date of the period of registered accruals under the condition of retro-bonuses of customers
// 
// Parameters:
//  TermDocument - DocumentRef.ConditionsOfCustomerRebates -
// 
// Returns:
//  Date - maximum end date of the period of registered accruals:
//
Function LimitOfAccrualsOfClients(TermDocument) Export
	
	SetPrivilegedMode(True);
	
	Result = Date(1, 1, 1);
	
	Query = New Query;
	Query.SetParameter("TermDocument", TermDocument);
	Query.Text = 
	"SELECT
	|	CustomerRebates.TermDocument,
	|	MAX(CustomerRebates.PeriodEnding) AS EndOfAccrualPeriod
	|FROM
	|	AccumulationRegister.CustomerRebates AS CustomerRebates
	|WHERE
	|	CustomerRebates.TermDocument = &TermDocument
	|	AND CustomerRebates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND CustomerRebates.Recorder <> &TermDocument
	|GROUP BY
	|	CustomerRebates.TermDocument";
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		Selection.Next();
		Result = Selection.EndOfAccrualPeriod; // Date
		
	EndIf;
	
	Return Result;
	
EndFunction

// Determines the maximum date of the period of registered accruals under the condition of retro-bonuses of suppliers
// 
// Parameters:
//  TermDocument - DocumentRef.ConditionsOfVendorRebates -
// 
// Returns:
//  Date - maximum end date of the period of registered accruals
//
Function LimitOfSupplierCharges(TermDocument) Export
	
	SetPrivilegedMode(True);
	
	Result = Date(1, 1, 1);
	
	Query = New Query;
	Query.SetParameter("TermDocument", TermDocument);
	Query.Text = 
	"SELECT
	|	VendorRebates.TermDocument AS TermDocument,
	|	MAX(CASE
	|		WHEN VendorRebates.PeriodEnding = DATETIME(1, 1, 1)
	|			THEN DATETIME(3999, 12, 31)
	|		ELSE VendorRebates.PeriodEnding
	|	END) AS EndOfAccrualPeriod
	|FROM
	|	AccumulationRegister.VendorRebates AS VendorRebates
	|WHERE
	|	VendorRebates.TermDocument = &TermDocument
	|	AND VendorRebates.TypeOfRegisterMovement = VALUE(Enum.AccumulationRecordTypes.Receipt)
	|	AND VendorRebates.Recorder <> &TermDocument
	|GROUP BY
	|	VendorRebates.TermDocument";
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		Selection.Next();
		Result = Selection.EndOfAccrualPeriod; // Date
		
	EndIf;
	
	Return Result;
	
EndFunction

// Fixes the current composition of the conditions document for further calculation
// 
// Parameters:
//  Document - DocumentRef.ConditionsOfCustomerRebates
//
Procedure RecordCompositionOfURBClients(Document) Export
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock();
		LockItem = Block.Add("InformationRegister.CustomerRebatesItemSegments");
		LockItem.SetValue("TermDocument", Document);
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem = Block.Add("InformationRegister.CustomerRebatesItems");
		LockItem.SetValue("TermDocument", Document);
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem = Block.Add("InformationRegister.CustomerRebatesPartnerSegments");
		LockItem.SetValue("TermDocument", Document);
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem = Block.Add("InformationRegister.CustomerRebatesCounterparties");
		LockItem.SetValue("TermDocument", Document);
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem = Block.Add("InformationRegister.CustomerRebatesConditions");
		LockItem.SetValue("TermDocument", Document);
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		AdjustmentHasBeenIntroducedForApproval = ThereIsAdjustmentOnApproval(Document);
		If AdjustmentHasBeenIntroducedForApproval Then
			
			ExceptionText = NStr("vi = 'Theo chứng từ điều kiện đã nhập điều chỉnh với trạng thái ""Đang thống nhất""';
								|ru = 'По документу условий введена корректировка в статусе ""На согласовании""';
								|en = 'For the condition document, an adjustment is registered in the ""On approval"" status.'; fa = 'For the condition document, an adjustment is registered in the ""On approval"" status.';
								|it = 'По документу условий введена корректировка в статусе ""На согласовании""';
								|pl = 'For the condition document, an adjustment is registered in the ""On approval"" status.';
								|tr = 'Koşullar belgesi için “Onay aşamasında” durumunda düzeltme girildi'");
			Raise ExceptionText;
			
		EndIf;
		
		FixSegments = False;
		
		SetPrivilegedMode(True);
		
		ContentOfGoods = Undefined;
		
		CurrentDocumentData = Documents.ConditionsOfCustomerRebates.UpToDateData(Document);
		If CurrentDocumentData.ContentOfGoods = Enums.RebatesItems.ProductSegments Then
			
			ContentOfGoods = CompositionOfGoodsSegments(Document);
			FixSegments = True;
			
		ElsIf CurrentDocumentData.ContentOfGoods = Enums.RebatesItems.ProductItemProperty Then
			
			ContentOfGoods = CompositionOfItemsByProperty(Document);
			FixSegments = True;
			
		EndIf;
		
		If ContentOfGoods <> Undefined
		   And ContentOfGoods.Count() > 0 Then
			
			SetOfGoodsRecords = InformationRegisters.CustomerRebatesItems.CreateRecordSet();
			SetOfGoodsRecords.Filter.TermDocument.Set(Document);
			SetOfGoodsRecords.Load(ContentOfGoods);
			SetOfGoodsRecords.Write();
			
		EndIf;
		
		If CurrentDocumentData.PartyList = Enums.RebatesParticipants.PartnersSegments Then
			
			CompositionOfPartners = CompositionOfPartnerSegments(Document);
			If CompositionOfPartners.Count() > 0 Then
				
				SetOfRecordsCounterparties = InformationRegisters.CustomerRebatesCounterparties.CreateRecordSet();
				SetOfRecordsCounterparties.Filter.TermDocument.Set(Document);
				SetOfRecordsCounterparties.Load(CompositionOfPartners);
				SetOfRecordsCounterparties.Write();
				
			EndIf;
			
			FixSegments = True;
			
		EndIf;
		
		If FixSegments Then
			
			SetOfConditionRecords = InformationRegisters.CustomerRebatesConditions.CreateRecordSet();
			SetOfConditionRecords.Filter.TermDocument.Set(Document);
			SetOfConditionRecords.Read();
			For Each RecordingConditions In SetOfConditionRecords Do
				
				RecordingConditions.RecordingIsCompleted = True;
				
			EndDo;
			SetOfConditionRecords.Write();
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Fixes the current composition of the conditions document for further calculation
// 
// Parameters:
//  Document - DocumentRef.ConditionsOfVendorRebates
//
Procedure FixCompositionOfSuppliersURB(Document) Export
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock();
		LockItem = Block.Add("InformationRegister.VendorRebatesGoodsSegments");
		LockItem.SetValue("TermDocument", Document);
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem = Block.Add("InformationRegister.VendorRebatesGoods");
		LockItem.SetValue("TermDocument", Document);
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem = Block.Add("InformationRegister.VendorRebatesConditions");
		LockItem.SetValue("TermDocument", Document);
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		AdjustmentHasBeenIntroducedForApproval = ThereIsAdjustmentOnApproval(Document);
		If AdjustmentHasBeenIntroducedForApproval Then
			
			ExceptionText = NStr("vi = 'Theo chứng từ điều kiện đã nhập điều chỉnh với trạng thái ""Đang thống nhất"".';
								|ru = 'По документу условий введена корректировка в статусе ""На согласовании"".';
								|en = 'For the condition document, an adjustment is registered in the ""On approval"" status.'; fa = 'For the condition document, an adjustment is registered in the ""On approval"" status.';
								|it = 'По документу условий введена корректировка в статусе ""На согласовании"".';
								|pl = 'For the condition document, an adjustment is registered in the ""On approval"" status.';
								|tr = 'Koşullar belgesi için “Onay bekliyor” durumunda düzeltme girildi.'");
			Raise ExceptionText;
			
		EndIf;
		
		SetPrivilegedMode(True);
		
		FixSegments = False;
		ContentOfGoods = Undefined;
		
		CurrentDocumentData = Documents.ConditionsOfVendorRebates.UpToDateData(Document);
		If CurrentDocumentData.ContentOfGoods = Enums.RebatesItems.ProductSegments Then
			
			ContentOfGoods = CompositionOfGoodsSegments(Document);
			FixSegments = True;
			
		ElsIf CurrentDocumentData.ContentOfGoods = Enums.RebatesItems.ProductItemProperty Then
			
			ContentOfGoods = CompositionOfItemsByProperty(Document);
			FixSegments = True;
			
		EndIf;
		
		If ContentOfGoods <> Undefined
		   And ContentOfGoods.Count() > 0 Then
			
			SetOfGoodsRecords = InformationRegisters.VendorRebatesGoods.CreateRecordSet();
			SetOfGoodsRecords.Filter.TermDocument.Set(Document);
			SetOfGoodsRecords.Load(ContentOfGoods);
			SetOfGoodsRecords.Write();
			
		EndIf;
		
		If FixSegments Then
			
			SetOfConditionRecords = InformationRegisters.VendorRebatesConditions.CreateRecordSet();
			SetOfConditionRecords.Filter.TermDocument.Set(Document);
			SetOfConditionRecords.Read();
			For Each RecordingConditions In SetOfConditionRecords Do
				
				RecordingConditions.RecordingIsCompleted = True;
				
			EndDo;
			SetOfConditionRecords.Write();
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Cancels fixing the composition of the conditions document
// 
// Parameters:
//  Document - DocumentRef.ConditionsOfCustomerRebates
//
Procedure CancelFixingCompositionOfURBClients(Document) Export
	
	QueryText =
	"SELECT TOP 1
	|	CustomerRebatesConditions.PartyList AS PartyList,
	|	ISNULL(CustomerRebatesConditions.Kind.ProductItemProperty, """") AS ProductItemProperty,
	|	CustomerRebatesConditions.ContentOfGoods AS ContentOfGoods
	|FROM
	|	InformationRegister.CustomerRebatesConditions AS CustomerRebatesConditions
	|WHERE
	|	CustomerRebatesConditions.TermDocument = &TermDocument
	|	AND CustomerRebatesConditions.RecordingIsCompleted";
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock();
		LockItem = Block.Add("InformationRegister.CustomerRebatesItems");
		LockItem.SetValue("TermDocument", Document);
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem = Block.Add("InformationRegister.CustomerRebatesCounterparties");
		LockItem.SetValue("TermDocument", Document);
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem = Block.Add("InformationRegister.CustomerRebatesConditions");
		LockItem.SetValue("TermDocument", Document);
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("TermDocument", Document);
		QueryResult = Query.Execute();
		SegmentsAreRecorded = Not QueryResult.IsEmpty();
		
		If SegmentsAreRecorded Then
			
			SetPrivilegedMode(True);
			
			Selection = QueryResult.Select();
			Selection.Next();
			
			If Selection.ContentOfGoods = Enums.RebatesItems.ProductSegments
			 Or Not IsBlankString(Selection.ProductItemProperty) Then
				
				SetOfGoodsRecords = InformationRegisters.CustomerRebatesItems.CreateRecordSet();
				SetOfGoodsRecords.Filter.TermDocument.Set(Document);
				SetOfGoodsRecords.Clear();
				SetOfGoodsRecords.Write();
				
			EndIf;
			
			If Selection.PartyList = Enums.RebatesParticipants.PartnersSegments Then
				
				SetOfRecordsCounterparties = InformationRegisters.CustomerRebatesCounterparties.CreateRecordSet();
				SetOfRecordsCounterparties.Filter.TermDocument.Set(Document);
				SetOfRecordsCounterparties.Clear();
				SetOfRecordsCounterparties.Write();
				
			EndIf;
			
			SetOfConditionRecords = InformationRegisters.CustomerRebatesConditions.CreateRecordSet();
			SetOfConditionRecords.Filter.TermDocument.Set(Document);
			SetOfConditionRecords.Read();
			For Each RecordingConditions In SetOfConditionRecords Do
				
				RecordingConditions.RecordingIsCompleted = False;
				
			EndDo;
			SetOfConditionRecords.Write();
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Cancels fixing the composition of the conditions document
// 
// Parameters:
//  Document - DocumentRef.ConditionsOfVendorRebates
//
Procedure CancelFixingListOfSuppliersURBS(Document) Export
	
	QueryText =
	"SELECT TOP 1
	|	TermsAndConditionsOfRebates.ContentOfGoods AS ContentOfGoods,
	|	ISNULL(TermsAndConditionsOfRebates.Kind.ProductItemProperty, """") AS ProductItemProperty
	|FROM
	|	InformationRegister.VendorRebatesConditions AS TermsAndConditionsOfRebates
	|WHERE
	|	TermsAndConditionsOfRebates.TermDocument = &TermDocument
	|	AND TermsAndConditionsOfRebates.RecordingIsCompleted";
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock();
		LockItem = Block.Add("InformationRegister.VendorRebatesGoods");
		LockItem.SetValue("TermDocument", Document);
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem = Block.Add("InformationRegister.VendorRebatesConditions");
		LockItem.SetValue("TermDocument", Document);
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("TermDocument", Document);
		QueryResult = Query.Execute();
		SegmentsAreRecorded = Not QueryResult.IsEmpty();
		
		If SegmentsAreRecorded Then
			
			SetPrivilegedMode(True);
			
			Selection = QueryResult.Select();
			Selection.Next();
			
			If Selection.ContentOfGoods = Enums.RebatesItems.ProductSegments
			 Or Not IsBlankString(Selection.ProductItemProperty) Then
				
				SetOfGoodsRecords = InformationRegisters.VendorRebatesGoods.CreateRecordSet();
				SetOfGoodsRecords.Filter.TermDocument.Set(Document);
				SetOfGoodsRecords.Clear();
				SetOfGoodsRecords.Write();
				
			EndIf;
			
			SetOfConditionRecords = InformationRegisters.VendorRebatesConditions.CreateRecordSet();
			SetOfConditionRecords.Filter.TermDocument.Set(Document);
			SetOfConditionRecords.Read();
			For Each RecordingConditions In SetOfConditionRecords Do
				
				RecordingConditions.RecordingIsCompleted = False;
				
			EndDo;
			SetOfConditionRecords.Write();
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Returns a table of products included in the segments of the document corresponding to the structure of the PC retrobonusiclient Products
//
// Parameters:
//  Document - DocumentRef.ConditionsOfCustomerRebates -
//           - DocumentRef.ConditionsOfVendorRebates -
// 
// Returns:
//  See NewCompositionOfGoodsSegments
//
Function CompositionOfGoodsSegments(Document) Export
	
	CompositionOfGoodsSegments = NewCompositionOfGoodsSegments(Document);
	
	ActualDocument = UpToDateDocumentOfRebatesTermsAndConditionsCanBeFoundAtLink(Document);
	If Not ActualDocument.IsEmpty() Then
		
		ItemOfSegments = FillInDataForFixingGoodsSegments(Document);
		If ItemOfSegments.Count() > 0 Then
			
			ManagerOfDocument = Common.ObjectManagerByRef(Document);
			DocumentData = ManagerOfDocument.UpToDateData(Document);
			SortItemSegmentTableByPresentation(ItemOfSegments);
			Counter = 1;
			
			For Each ProductData_1 In ItemOfSegments Do
				
				NewRow = CompositionOfGoodsSegments.Add();
				FillPropertyValues(NewRow, DocumentData);
				FillPropertyValues(NewRow, ProductData_1);
				NewRow.TermDocument = Document;
				NewRow.RecorderDocument = ActualDocument;
				NewRow.DocumentRowNumber = Counter;
				
				Counter = Counter + 1;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Return CompositionOfGoodsSegments;
	
EndFunction

// Returns a table of partners included in the document segments corresponding to the structure of the PC retrobonusiclientscontragents
//
// Parameters:
//  Document - DocumentRef.ConditionsOfCustomerRebates
// 
// Returns:
//  ValueTable:
//  * ValidOnDate - Date
//  * ValidTo - Date
//  * TermDocument - DocumentRef.ConditionsOfCustomerRebates
//  * Counterparty - CatalogRef.Counterparties
//  * Partner - CatalogRef.Partners
//  * SumPlan - DefinedType.MonetaryAmountNonNegative
//  * RecorderDocument - DocumentRef.ConditionsOfCustomerRebates
//
Function CompositionOfPartnerSegments(Document) Export
	
	CompositionOfPartnerSegments = InformationRegisters.CustomerRebatesCounterparties.CreateRecordSet().Unload();
	
	ActualDocument = UpToDateDocumentOfRebatesTermsAndConditionsCanBeFoundAtLink(Document);
	If Not ActualDocument.IsEmpty() Then
		
		SegmentsPartners = FillInDataForFixingPartnerSegments(Document);
		
		If SegmentsPartners.Count() > 0 Then
			
			DocumentData = Documents.ConditionsOfCustomerRebates.UpToDateData(Document);
			SortPartnerSegmentTableByPresentation(SegmentsPartners);
			Counter = 1;
			
			For Each PartnerData In SegmentsPartners Do
				
				NewRow = CompositionOfPartnerSegments.Add();
				FillPropertyValues(NewRow, DocumentData);
				FillPropertyValues(NewRow, PartnerData);
				NewRow.TermDocument = Document;
				NewRow.RecorderDocument = ActualDocument;
				NewRow.DocumentRowNumber = Counter;
				
				Counter = Counter + 1;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Return CompositionOfPartnerSegments;
	
EndFunction

// Defines the name of the table part and the Presentation for the terms of the retro bonuses of customers according to the transmitted parameters
// 
// Parameters:
//  Content - EnumRef.RebatesParticipants, EnumRef.RebatesItems - 
//  FilterParties - EnumRef.RebatesLists - Selection of Participants
// 
// Returns:
//  Structure - Name Presentation of the table by Attributes:
// * TableName - String - 
// * TablePresentation - String - 
//
Function NamePresentationOfTableByDetailsOfCustomerConditions(Content, FilterParties) Export
	
	NamePresentationOfTable = New Structure;
	NamePresentationOfTable.Insert("TableName", "");
	NamePresentationOfTable.Insert("TablePresentation", "");
	
	If TypeOf(Content) = Type("EnumRef.RebatesParticipants") Then
		
		If Content = Enums.RebatesParticipants.Counterparties Then
			
			NamePresentationOfTable.TableName = "Counterparties";
			If FilterParties = Enums.RebatesLists.Selected_ Then
				NamePresentationOfTable.TablePresentation = NStr("vi = 'Đối tác được chọn';
																|ru = 'Выбранные контрагенты';
																|en = 'Selected counterparties'; fa = 'Selected counterparties';
																|it = 'Выбранные контрагенты';
																|pl = 'Selected counterparties';
																|tr = 'Seçili cari hesaplar'");
			Else
				NamePresentationOfTable.TablePresentation = NStr("vi = 'Ngoại trừ đối tác';
																|ru = 'Кроме контрагентов';
																|en = 'Except for counterparties'; fa = 'Except for counterparties';
																|it = 'Кроме контрагентов';
																|pl = 'Except for counterparties';
																|tr = 'Cari hesaplar hariç'");
			EndIf;
			
		ElsIf Content = Enums.RebatesParticipants.Customers Then
			
			NamePresentationOfTable.TableName = "Counterparties";
			If FilterParties = Enums.RebatesLists.Selected_ Then
				NamePresentationOfTable.TablePresentation = NStr("vi = 'Khách hàng được chọn';
																|ru = 'Выбранные клиенты';
																|en = 'Selected customers'; fa = 'Selected customers';
																|it = 'Выбранные клиенты';
																|pl = 'Selected customers';
																|tr = 'Seçili müşteriler'");
			Else
				NamePresentationOfTable.TablePresentation = NStr("vi = 'Ngoại trừ khách hàng';
																|ru = 'Кроме клиентов';
																|en = 'Except for customers'; fa = 'Except for customers';
																|it = 'Кроме клиентов';
																|pl = 'Except for customers';
																|tr = 'Müşteriler hariç'");
			EndIf;
			
		ElsIf Content = Enums.RebatesParticipants.TIN Then
			
			NamePresentationOfTable.TableName = "CounterpartiesTIN";
			If FilterParties = Enums.RebatesLists.Selected_ Then
				NamePresentationOfTable.TablePresentation = NStr("vi = 'MST được chọn';
																|ru = 'Выбранные ИНН';
																|en = 'Selected TIN'; fa = 'Selected TIN';
																|it = 'Выбранные ИНН';
																|pl = 'Selected TIN';
																|tr = 'Seçili VKN''ler'");
			Else
				NamePresentationOfTable.TablePresentation = NStr("vi = 'Ngoại trừ MST';
																|ru = 'Кроме ИНН';
																|en = 'Except for TIN'; fa = 'Except for TIN';
																|it = 'Кроме ИНН';
																|pl = 'Except for TIN';
																|tr = 'VKN hariç'");
			EndIf;
			
		ElsIf Content = Enums.RebatesParticipants.Contracts Then
			
			NamePresentationOfTable.TableName = "ContractsTermsOfSales";
			NamePresentationOfTable.TablePresentation = NStr("vi = 'Hợp đồng đã chọn';
															|ru = 'Выбранные договоры';
															|en = 'Selected contracts'; fa = 'Selected contracts';
															|it = 'Выбранные договоры';
															|pl = 'Selected contracts';
															|tr = 'Seçili sözleşmeler'");
			
		ElsIf Content = Enums.RebatesParticipants.Terms1 Then
			
			NamePresentationOfTable.TableName = "ContractsTermsOfSales";
			NamePresentationOfTable.TablePresentation = NStr("vi = 'Thỏa thuận đã chọn';
															|ru = 'Выбранные соглашения';
															|en = 'Selected terms of sales'; fa = 'Selected terms of sales';
															|it = 'Выбранные соглашения';
															|pl = 'Selected terms of sales';
															|tr = 'Seçili anlaşmalar'");
			
		EndIf;
		
	ElsIf TypeOf(Content) = Type("EnumRef.RebatesItems") Then
		
		If Content = Enums.RebatesItems.Products Then
			
			NamePresentationOfTable.TableName = "Goods";
			If FilterParties = Enums.RebatesLists.Selected_ Then
				NamePresentationOfTable.TablePresentation = NStr("vi = 'Hàng hóa được chọn';
																|ru = 'Выбранные товары';
																|en = 'Selected goods'; fa = 'کالای انتخاب‌شده';
																|it = 'Выбранные товары';
																|pl = 'Wybrane towary';
																|tr = 'Seçili ürünler'");
			Else
				NamePresentationOfTable.TablePresentation = NStr("vi = 'Ngoại trừ mặt hàng';
																|ru = 'Кроме товаров';
																|en = 'Except for goods'; fa = 'Except for goods';
																|it = 'Кроме товаров';
																|pl = 'Except for goods';
																|tr = 'Ürünler hariç'");
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return NamePresentationOfTable;
	
EndFunction

// Defines the name of the table part and the Presentation for the terms of suppliers' retro bonuses based on the passed parameters
// 
// Parameters:
//  Content - EnumRef.RebatesParticipants, EnumRef.RebatesItems - 
//  FilterParties - EnumRef.RebatesLists - Selection of Participants
// 
// Returns:
//  Structure - Name Presentation of the table by Attributes:
// * TableName - String - 
// * TablePresentation - String - 
//
Function NamePresentationOfTableByAttributesOfVendorConditions(Content, FilterParties) Export
	
	NamePresentationOfTable = New Structure;
	NamePresentationOfTable.Insert("TableName", "");
	NamePresentationOfTable.Insert("TablePresentation", "");
	
	If TypeOf(Content) = Type("EnumRef.RebatesParticipants") Then
		
		If Content = Enums.RebatesParticipants.Counterparties Then
			
			NamePresentationOfTable.TableName = "CustomerCounterparties";
			If FilterParties = Enums.RebatesLists.Selected_ Then
				NamePresentationOfTable.TablePresentation = NStr("vi = 'Khách hàng: đối tác được chọn';
																|ru = 'Клиенты: выбранные контрагенты';
																|en = 'Customers: selected counterparties'; fa = 'Customers: selected counterparties';
																|it = 'Клиенты: выбранные контрагенты';
																|pl = 'Customers: selected counterparties';
																|tr = 'Müşteriler: Seçili cari hesaplar'");
			Else
				NamePresentationOfTable.TablePresentation = NStr("vi = 'Khách hàng: ngoài đối tác';
																|ru = 'Клиенты: кроме контрагентов';
																|en = 'Customers: except for counterparties'; fa = 'Customers: except for counterparties';
																|it = 'Клиенты: кроме контрагентов';
																|pl = 'Customers: except for counterparties';
																|tr = 'Müşteriler: Cari hesaplar hariç'");
			EndIf;
			
		ElsIf Content = Enums.RebatesParticipants.TIN Then
			
			NamePresentationOfTable.TableName = "ClientsCounterpartiesTIN";
			If FilterParties = Enums.RebatesLists.Selected_ Then
				NamePresentationOfTable.TablePresentation = NStr("vi = 'Khách hàng: MST được chọn';
																|ru = 'Клиенты: выбранные ИНН';
																|en = 'Customers: selected TIN'; fa = 'Customers: selected TIN';
																|it = 'Клиенты: выбранные ИНН';
																|pl = 'Customers: selected TIN';
																|tr = 'Müşteriler: Seçili VKN''ler'");
			Else
				NamePresentationOfTable.TablePresentation = NStr("vi = 'Khách hàng: ngoài MST';
																|ru = 'Клиенты: кроме ИНН';
																|en = 'Customers: except TIN'; fa = 'Customers: except TIN';
																|it = 'Клиенты: кроме ИНН';
																|pl = 'Customers: except TIN';
																|tr = 'Müşteriler: VKN''ler hariç'");
			EndIf;
			
		EndIf;
		
	ElsIf TypeOf(Content) = Type("EnumRef.RebatesItems") Then
		
		If Content = Enums.RebatesItems.Products Then
			
			NamePresentationOfTable.TableName = "Goods";
			If FilterParties = Enums.RebatesLists.Selected_ Then
				NamePresentationOfTable.TablePresentation = NStr("vi = 'Hàng hóa được chọn';
																|ru = 'Выбранные товары';
																|en = 'Selected goods'; fa = 'کالای انتخاب‌شده';
																|it = 'Выбранные товары';
																|pl = 'Wybrane towary';
																|tr = 'Seçili ürünler'");
			Else
				NamePresentationOfTable.TablePresentation = NStr("vi = 'Ngoại trừ mặt hàng';
																|ru = 'Кроме товаров';
																|en = 'Except for goods'; fa = 'Except for goods';
																|it = 'Кроме товаров';
																|pl = 'Except for goods';
																|tr = 'Ürünler hariç'");
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return NamePresentationOfTable;
	
EndFunction

// Returns:
//  Array of EnumRef.ItemsTypes
Function SupportedItemTypes() Export
	
	SupportedItemTypes = New Array; // Array of EnumRef.ItemsTypes
	SupportedItemTypes.Add(Enums.ItemsTypes.OwnGoods);
	SupportedItemTypes.Add(Enums.ItemsTypes.OperationService);
	SupportedItemTypes.Add(Enums.ItemsTypes.Work_5);
	
	Return SupportedItemTypes;
	
EndFunction

// See ReportsOptionsOverridable.CustomizeReportsOptions
Procedure CustomizeReportsOptions(Settings) Export
	
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.CustomerRebateStatement);
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.CalculateCustomerRebates);
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.ActiveCustomerRebates);
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.ActiveRebatesByTermsOfSales);
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.ActiveRebatesByContract);
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.CompositionOfCustomerRebates);
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.CompositionOfVendorRebates);
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.VendorRebateStatement);
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.CalculateVendorRebates);
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.ActiveVendorRebates);
	
EndProcedure

// Generates a Presentation of the calculation period for the report.
// 
// Parameters:
//  StartOfSettlementPeriod - Date
//  Periodicity - EnumRef.RebatesFrequencies - The time fence of the terms of retro bonuses
//  ReportPeriod - StandardPeriod
// 
// Returns:
//  String - String Presentation of the calculation period
//
Function PresentationOfCalculationPeriod(StartOfSettlementPeriod, Periodicity, ReportPeriod) Export
	
	StartOfSettlementPeriodPresentation = Format(StartOfSettlementPeriod, "DLF=D");
	PeriodPresentationTemplate = "%1 - %2";
	
	Periodicity_ = Enums.RebatesFrequencies;
	If Periodicity = Periodicity_.Day Then
		
		PeriodPresentation = StartOfSettlementPeriodPresentation;
		
	ElsIf Periodicity = Periodicity_.Week Then
		
		EndOfPeriod = EndOfWeek(StartOfSettlementPeriod);
		EndOfPeriodPresentation = Format(EndOfPeriod, "DLF=D");
		PeriodPresentation = StrTemplate(
			PeriodPresentationTemplate, StartOfSettlementPeriodPresentation, EndOfPeriodPresentation);
		
	ElsIf Periodicity = Periodicity_.Month Then
		
		EndOfPeriod = EndOfMonth(StartOfSettlementPeriod);
		PeriodPresentation = PeriodPresentation(StartOfSettlementPeriod, EndOfPeriod);
		
	ElsIf Periodicity = Periodicity_.Quarter Then
		
		EndOfPeriod = EndOfQuarter(StartOfSettlementPeriod);
		PeriodPresentation = PeriodPresentation(StartOfSettlementPeriod, EndOfPeriod);
		
	Else
		
		BeginningOfReportPeriodPresentation = Format(ReportPeriod.StartDate, "DLF=D");
		EndOfReportPeriodPresentation = Format(ReportPeriod.EndDate, "DLF=D");
		PeriodPresentation = StrTemplate(
			PeriodPresentationTemplate, BeginningOfReportPeriodPresentation, EndOfReportPeriodPresentation);
		
	EndIf;
	
	Return PeriodPresentation;
	
EndFunction

// Returns an indication of the availability of corrective documents with the "Under approval" status for the retro bonus terms document
// 
// Parameters:
//  Document - DocumentRef.ConditionsOfCustomerRebates, DocumentRef.ConditionsOfVendorRebates -
//
// Returns:
//  Boolean
//
Function ThereIsAdjustmentOnApproval(Document) Export
	
	AdjustmentOnApproval = UpToDateDocumentOfRebatesTermsAndConditionsCanBeFoundAtLink(
		Document,
		Enums.RebatesDocumentStatuses.AwaitingApproval);
	
	Result = (Not AdjustmentOnApproval.IsEmpty()
				  And AdjustmentOnApproval <> Document);
	
	Return Result;
	
EndFunction

// Name of the Balance control event
// 
// Returns:
//  String
//
Function EventNameResidueControlDisabled() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	Return NStr("vi = 'Kiểm soát số dư thưởng lũy kế';
				|ru = 'Контроль остатков ретро-бонусов';
				|en = 'Rebate balance check'; fa = 'Rebate balance check';
				|it = 'Контроль остатков ретро-бонусов';
				|pl = 'Rebate balance check';
				|tr = 'Retro-bonus bakiyelerinin kontrolü'", DefaultLanguageCode);
	
EndFunction

// Check the periods of the table.
// 
// Parameters:
//  VerificationObject - DocumentObject.ConditionsOfCustomerRebates, DocumentObject.ConditionsOfVendorRebates -
//  TableName - String - name of the table part to check
//  TablePresentation - String - Presentation of the table part being checked
//  Cancel - Boolean - Cancel
//
Procedure CheckTablePeriods(VerificationObject, Val TableName, Val TablePresentation, Cancel) Export
	
	DateEmpty = Date(1, 1, 1);
	
	If VerificationObject.ValidOnDate = DateEmpty
	   And VerificationObject.ValidTo = DateEmpty Then
		Return;
	EndIf;
	
	MessageTemplate = NStr("vi = 'Tại dòng %1 của danh sách %2 đã chỉ định %3 không khớp với kỳ hiệu lực thưởng lũy kế';
							|ru = 'В строке %1 списка %2 указана %3, не соответствующая периоду действия ретро-бонуса';
							|en = 'In line %1 of the %2 list, %3, which mismatches the rebate period, is specified'; fa = 'In line %1 of the %2 list, %3, which mismatches the rebate period, is specified';
							|it = 'В строке %1 списка %2 указана %3, не соответствующая периоду действия ретро-бонуса';
							|pl = 'In line %1 of the %2 list, %3, which mismatches the rebate period, is specified';
							|tr = '%2 listesinin %1 satırı retro bonus dönemine tekabül etmeyen %3 belirtilmiştir'");
	MessageTemplatePeriodError = NStr("vi = 'Tại dòng %1 của danh sách %2 ngày đầu kỳ lớn hơn ngày cuối kỳ';
										|ru = 'В строке %1 списка %2 дата начала больше даты окончания';
										|en = 'Start date is later than the end date in line %1 of the %2 list'; fa = 'Start date is later than the end date in line %1 of the %2 list';
										|it = 'В строке %1 списка %2 дата начала больше даты окончания';
										|pl = 'Start date is later than the end date in line %1 of the %2 list';
										|tr = '%2 listesinin %1 satırında başlangıç tarihi bitiş tarihinden daha ileri'");
	ContainsCanceled = Undefined;
	
	ObjectTabularSection = VerificationObject[TableName]; // DocumentTabularSection.ConditionsOfCustomerRebates.Counterparties, DocumentTabularSection.ConditionsOfCustomerRebates.CounterpartiesTIN, DocumentTabularSection.ConditionsOfCustomerRebates.ContractsTermsOfSales, DocumentTabularSection.ConditionsOfCustomerRebates.Goods, DocumentTabularSection.ConditionsOfCustomerRebates.ProductProperties_, DocumentTabularSection.ConditionsOfVendorRebates.Goods, DocumentTabularSection.ConditionsOfVendorRebates.Vendors  
	For Each TSRow In ObjectTabularSection Do
		
		#Region EndingIsBiggerThanBeginning
		If TSRow.ValidOnDate <> DateEmpty
		   And TSRow.ValidTo <> DateEmpty
		   And TSRow.ValidOnDate > TSRow.ValidTo Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplatePeriodError, String(TSRow.LineNumber), TablePresentation);
			
			Field = CommonClientServer.PathToTabularSection(
				TableName, TSRow.LineNumber, "ValidOnDate");
			Common.MessageToUser(MessageText, VerificationObject, Field,, Cancel);
			
		EndIf;
		#EndRegion
		
		If ContainsCanceled = Undefined Then
			ContainsCanceled =  CommonClientServer.HasAttributeOrObjectProperty(TSRow, "Canceled");
		EndIf;
		
		ExecuteCheck1 = True;
		If ContainsCanceled
		   And TSRow.Canceled Then
			ExecuteCheck1 = False;
		EndIf;
		
		#Region BeginningInValidityPeriod
		If ExecuteCheck1
		   And TSRow.ValidOnDate <> DateEmpty
		   And Not (TSRow.ValidOnDate >= VerificationObject.ValidOnDate
				 And TSRow.ValidOnDate <= VerificationObject.ValidTo) Then
			
			FieldPresentation = NStr("vi = 'ngày bắt đầu';
									|ru = 'дата начала';
									|en = 'start date'; fa = 'start date';
									|it = 'дата начала';
									|pl = 'start date';
									|tr = 'başlangıç tarihi'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate,
				Format(TSRow.LineNumber, "NG=;"),
				TablePresentation,
				FieldPresentation);
				
			Field = CommonClientServer.PathToTabularSection(
				TableName, TSRow.LineNumber, "ValidOnDate");
			Common.MessageToUser(MessageText, VerificationObject, Field,, Cancel);
			
		EndIf;
		#EndRegion
		
		#Region EndInValidityPeriod
		If ExecuteCheck1
		   And TSRow.ValidTo <> DateEmpty
		   And Not (TSRow.ValidTo >= VerificationObject.ValidOnDate
				 And TSRow.ValidTo <= VerificationObject.ValidTo) Then
			
			FieldPresentation = NStr("vi = 'ngày kết thúc';
									|ru = 'дата окончания';
									|en = 'end date'; fa = 'end date';
									|it = 'дата окончания';
									|pl = 'end date';
									|tr = 'bitiş tarihi'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate,
				Format(TSRow.LineNumber, "NG=;"),
				TablePresentation,
				FieldPresentation);
				
			Field = CommonClientServer.PathToTabularSection(
				TableName, TSRow.LineNumber, "ValidTo");
			Common.MessageToUser(MessageText, VerificationObject, Field,, Cancel);
			
		EndIf;
		#EndRegion
		
		#Region Periodicity
		CheckResult = CheckPeriodsByTimeFence(
			VerificationObject.ConditionFrequency,
			TSRow.ValidOnDate, 
			TSRow.ValidTo);
		
		If CheckResult.ThereIsViolationOfBeginning Then
			
			ErrorText = CommonClientServer.FillingErrorText(
				"Column",
				"Correctness",
				NStr("vi = 'Ngày đầu hiệu lực';
					|ru = 'Начало действия';
					|en = 'Valid from'; fa = 'معتبر از';
					|it = 'Начало действия';
					|pl = 'Początek działania';
					|tr = 'Eylem başlangıcı'"),
				Format(TSRow.LineNumber, "NG=;"),
				TablePresentation,
				CheckResult.TextOfStartError);
			
			PathToField = CommonClientServer.PathToTabularSection(
				TableName, TSRow.LineNumber, "ValidOnDate");
			
			Common.MessageToUser(ErrorText, VerificationObject, PathToField,, Cancel);
			
		EndIf;
		
		If CheckResult.ThereIsViolationOfEnding Then
			
			ErrorText = CommonClientServer.FillingErrorText(
				"Column",
				"Correctness",
				NStr("vi = 'Ngày hết hiệu lực';
					|ru = 'Окончание действия';
					|en = 'Valid to'; fa = 'معتبر تا';
					|it = 'Окончание действия';
					|pl = 'Zakończenie czynności';
					|tr = 'Eylem bitişi'"),
				Format(TSRow.LineNumber, "NG=;"),
				TablePresentation,
				CheckResult.TextOfEndingError);
			
			PathToField = CommonClientServer.PathToTabularSection(
				TableName, TSRow.LineNumber, "ValidTo");
			
			Common.MessageToUser(ErrorText, VerificationObject, PathToField,, Cancel);
			
		EndIf;
		#EndRegion
		
	EndDo;
	
EndProcedure

// Check for valid rows in the table part
// 
// Parameters:
//  VerificationObject - DocumentObject.ConditionsOfCustomerRebates, DocumentObject.ConditionsOfVendorRebates -
//  TableName - String - name of the table part to check
//  TablePresentation - String - Presentation of the table part being checked
//  Cancel - Boolean - Cancel
//
Procedure CheckForValidLines(VerificationObject, Val TableName, TablePresentation, Cancel) Export
	
	If Not VerificationObject.Patch Then
		Return;
	EndIf;
	
	TabularSection = VerificationObject[TableName]; // TabularSection
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Canceled", True);
	NumberOfRowsTotal = TabularSection.Count();
	RowsCountCanceled = TabularSection.FindRows(FilterStructure1).Count();
	
	AllTSLinesAreCanceled = (NumberOfRowsTotal = RowsCountCanceled);
	
	If AllTSLinesAreCanceled Then
		
		ReasonText = NStr("vi = 'Tất cả các dòng đã bị hủy, cần ít nhất một dòng có hiệu lực';
							|ru = 'Все строки отменены, должна быть хотя бы одна действующая строка';
							|en = 'All lines are canceled. There must be at least one valid line'; fa = 'All lines are canceled. There must be at least one valid line';
							|it = 'Все строки отменены, должна быть хотя бы одна действующая строка';
							|pl = 'All lines are canceled. There must be at least one valid line';
							|tr = 'Tüm satırlar iptal edildi, en az bir adet geçerli satır olmalıdır'");
		MessageText = CommonClientServer.FillingErrorText(
			"List",
			"Correctness",
			,
			,
			TablePresentation,
			ReasonText);
		
		Common.MessageToUser(MessageText, VerificationObject, TableName,, Cancel);
		
	EndIf;
	
EndProcedure

// Parameters:
//  InitializationObject - DocumentObject.ConditionsOfCustomerRebates, DocumentObject.ConditionsOfVendorRebates -
//  TableName - String - name of the table part to check
//  NamesOfFieldsToBeCleared - Undefined, Array of String - the names of the fields in the table part that need to be cleared additionally
//
Procedure InitializeListToBeCopied(InitializationObject, Val TableName, NamesOfFieldsToBeCleared = Undefined) Export
	
	RowsForDeletion = New Array; // Array of DocumentTabularSectionRow.ConditionsOfCustomerRebates.Counterparties, DocumentTabularSectionRow.ConditionsOfCustomerRebates.CounterpartiesTIN, DocumentTabularSectionRow.ConditionsOfCustomerRebates.ContractsTermsOfSales, DocumentTabularSectionRow.ConditionsOfCustomerRebates.Goods, DocumentTabularSection.ConditionsOfCustomerRebates.ProductProperties_, DocumentTabularSectionRow.ConditionsOfCustomerRebates.PartnersSegments, DocumentTabularSectionRow.ConditionsOfCustomerRebates.GoodsSegments, DocumentTabularSectionRow.ConditionsOfVendorRebates.Goods, DocumentTabularSectionRow.ConditionsOfVendorRebates.CustomerCounterparties, DocumentTabularSectionRow.ConditionsOfVendorRebates.ClientsCounterpartiesTIN
	
	TabularSection = InitializationObject[TableName]; // DocumentTabularSection.ConditionsOfCustomerRebates.Counterparties, DocumentTabularSection.ConditionsOfCustomerRebates.CounterpartiesTIN, DocumentTabularSection.ConditionsOfCustomerRebates.ContractsTermsOfSales, DocumentTabularSection.ConditionsOfCustomerRebates.Goods, DocumentTabularSection.ConditionsOfCustomerRebates.ProductProperties_, DocumentTabularSection.ConditionsOfCustomerRebates.PartnersSegments, DocumentTabularSection.ConditionsOfCustomerRebates.GoodsSegments, DocumentTabularSection.ConditionsOfVendorRebates.Goods, DocumentTabularSection.ConditionsOfVendorRebates.CustomerCounterparties, DocumentTabularSection.ConditionsOfVendorRebates.ClientsCounterpartiesTIN
	
	For Each TSRow In TabularSection Do
		
		If TSRow.Canceled Then
			
			RowsForDeletion.Add(TSRow);
			
		Else
			
			TSRow.InitialString = False;
			
			If NamesOfFieldsToBeCleared <> Undefined Then
				
				For Each FieldName In NamesOfFieldsToBeCleared Do
					TSRow[FieldName] = Undefined;
				EndDo;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	For Each String In RowsForDeletion Do
		TabularSection.Delete(String);
	EndDo;
	
EndProcedure

// Parameters:
//  CorrectedDocument - DocumentRef.ConditionsOfCustomerRebates, DocumentRef.ConditionsOfVendorRebates -
//  ReversedDocument - DocumentRef.ConditionsOfCustomerRebates, DocumentRef.ConditionsOfVendorRebates -
//  ChainID - String -
//  WriteMode - DocumentWriteMode
//
Procedure CheckChainOfDocuments(Val CorrectedDocument, Val ReversedDocument, Val ChainID,  Val WriteMode) Export
	
	If CorrectedDocument.IsEmpty() Then
		Return;
	EndIf;
	
	AttributesOfItemBeingCorrected = Common.ObjectAttributesValues(
		CorrectedDocument, "ChainID");
	
	If AttributesOfItemBeingCorrected.ChainID <> ChainID
	   And WriteMode = DocumentWriteMode.Posting Then
		
		ErrorText = NStr("vi = 'Chứng từ chỉnh sửa đã được thống nhất lại, cấm sử dụng điều chỉnh hiện tại.
						   |Hãy tạo chứng từ điều chỉnh mới.';
						   |ru = 'Исправляемый документ был пересогласован, текущая корректировка запрещена к использованию.
						   |Создайте новый документ корректировки.';
						   |en = 'The document to correct was reapproved. The current adjustment cannot be used.
						   |Create a new adjustment document.'; fa = 'The document to correct was reapproved. The current adjustment cannot be used.
						   |Create a new adjustment document.';
						   |it = 'Исправляемый документ был пересогласован, текущая корректировка запрещена к использованию.
						   |Создайте новый документ корректировки.';
						   |pl = 'The document to correct was reapproved. The current adjustment cannot be used.
						   |Create a new adjustment document.';
						   |tr = 'Düzeltilmesi gereken belge yeniden düzenlendi, mevcut düzeltmenin kullanımı yasaktır.
						   |Yeni bir düzeltme belgesi oluşturun.'");
		Raise ErrorText
		
	EndIf;
	
	AttributesOfBeingCancelled = Common.ObjectAttributesValues(
		ReversedDocument, "Status");
		
	If AttributesOfBeingCancelled.Status <> Enums.RebatesDocumentStatuses.Approved Then
		
		ErrorText = NStr("vi = 'Bản chỉnh sửa trước đó của chứng từ chưa được thống nhất, cấm kết chuyển chứng từ.';
						|ru = 'Предыдущее исправление документ не согласовано, проведение документа запрещено.';
						|en = 'The previous correction of the document is not approved. Cannot post the document.'; fa = 'The previous correction of the document is not approved. Cannot post the document.';
						|it = 'Предыдущее исправление документ не согласовано, проведение документа запрещено.';
						|pl = 'The previous correction of the document is not approved. Cannot post the document.';
						|tr = 'Önceki düzeltme belgesi kabul edilmedi, belgenin uygulanması yasaktır.'");
		Raise ErrorText
		
	EndIf;
	
EndProcedure

// Parameters:
//  Object - DocumentObject.ConditionsOfCustomerRebates, DocumentObject.ConditionsOfVendorRebates -
//  TableName - String
//  TablePresentation - String
//  Cancel - Boolean
//
Procedure CheckFillingInINN(Object, TableName, TablePresentation, Cancel) Export
	
	TabularSection = Object[TableName]; // DocumentTabularSection.ConditionsOfCustomerRebates.CounterpartiesTIN, DocumentTabularSection.ConditionsOfVendorRebates.ClientsCounterpartiesTIN
	For Each TINLine In TabularSection Do
		
		TINLength = StrLen(TrimAll(TINLine.TIN));
		RowPath = CommonClientServer.PathToTabularSection(TableName, TINLine.LineNumber, "TIN");
		
		If IsBlankString(TINLine.TIN) Then
			
			// Platform verification will be triggered
			Continue;
			
		ElsIf TINLength <> 10
				And TINLength <> 12 Then
			
			DecodingError = NStr("vi = 'MST phải có 10 hoặc 12 số';
								|ru = 'ИНН должен состоять из 10 или 12 цифр';
								|en = 'TIN must contain 10 or 12 digits'; fa = 'TIN must contain 10 or 12 digits';
								|it = 'ИНН должен состоять из 10 или 12 цифр';
								|pl = 'TIN must contain 10 or 12 digits';
								|tr = 'VKN 10 ila 12 arasında rakamdan oluşmalıdır'");
			MessageText = CommonClientServer.FillingErrorText(
				"Column",
				"Correctness",
				"TIN",
				Format(TINLine.LineNumber, "NG=;"),
				TablePresentation,
				DecodingError);
			
			Common.MessageToUser(MessageText, Object, RowPath,, Cancel);
			
		Else
			
			CorrectINN = True;
			VerificationText = "";
			
			
			If Not CorrectINN Then
				
				MessageText = CommonClientServer.FillingErrorText(
				"Column",
				"Correctness",
				"TIN",
				Format(TINLine.LineNumber, "NG=;"),
				TablePresentation,
				VerificationText);
				
				Common.MessageToUser(MessageText, Object, RowPath,, Cancel);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  CalculationScales - DocumentTabularSection.ConditionsOfCustomerRebates.CalculationScales
//               - DocumentTabularSection.ConditionsOfVendorRebates.CalculationScales
//  CalculationScaleType - Number
//  KindAttributes - Structure:
//  	* GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods
//  Cancel - Boolean -
//
Procedure CheckCalculationScales(CalculationScales, CalculationScaleType, KindAttributes, Cancel) Export
	
	If KindAttributes.GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
	 Or CalculationScaleType = 0 Then
		Return;
	EndIf;
	
	If CalculationScaleType = 1 Then // Progressive Scale
		
		For Each ScaleLine In CalculationScales Do
			
			If ScaleLine.BonusPercent <> 0 Then
				Continue;
			EndIf;
			
			MessageText = CommonClientServer.FillingErrorText(
				"COLUMN",
				,
				NStr("vi = 'Thưởng, %';
					|ru = 'Бонус, %';
					|en = 'Rebate, %'; fa = 'تخفیف حجمی، درصد';
					|it = 'Бонус, %';
					|pl = 'Rebate, %';
					|tr = 'Bonus, %'"),
				Format(ScaleLine.LineNumber, "NG=;"),
				NStr("vi = 'Thang tính toán';
					|ru = 'Шкалы расчета';
					|en = 'Calculation scales'; fa = 'مقیاس‌های محاسبه';
					|it = 'Calculation scales';
					|pl = 'Calculation scales';
					|tr = 'Hesaplama ölçekleri'"));
			
			Field = CommonClientServer.PathToTabularSection(
				"CalculationScales", ScaleLine.LineNumber, "BonusPercent");
			Common.MessageToUser(MessageText,, Field, "Object", Cancel);
			
		EndDo;
		
	EndIf;
	
	If CalculationScaleType = 2 Then // By Ranges
		
		If CalculationScales.Count() = 1
		   And CalculationScales[0].RangeFrom = 0 Then
			
			MessageText = NStr("vi = 'Cần chỉ ra không nhỏ hơn hai khoảng thang tính toán';
								|ru = 'Требуется указание не менее двух диапазонов шкалы расчета';
								|en = 'Specify at least two calculation scale ranges'; fa = 'Specify at least two calculation scale ranges';
								|it = 'Specify at least two calculation scale ranges';
								|pl = 'Specify at least two calculation scale ranges';
								|tr = 'Hesaplama ölçeğinin en az iki aralığının belirtilmesi gerekmektedir'");
			Common.MessageToUser(MessageText,, "CalculationScales", "Object", Cancel);
			
		ElsIf CalculationScales.Count() > 0 Then
			
			FilterParameters = New Structure;
			FilterParameters.Insert("BonusPercent", 0);
			
			FoundRows = CalculationScales.FindRows(FilterParameters);
			If CalculationScales.Count() = FoundRows.Count() Then
				
				MessageText = NStr("vi = 'Phần trăm điểm thưởng cần được chỉ ra không nhỏ hơn đối với một trong số các khoảng';
									|ru = 'Процент бонуса должен быть указан не менее чем для одного из диапазонов';
									|en = 'Specify the rebate percentage for at least one of the ranges'; fa = 'Specify the rebate percentage for at least one of the ranges';
									|it = 'Specify the rebate percentage for at least one of the ranges';
									|pl = 'Specify the rebate percentage for at least one of the ranges';
									|tr = 'Bonus yüzdesi, aralıklardan en az birinde belirtilmelidir'");
				Common.MessageToUser(MessageText,, "CalculationScales", "Object", Cancel);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//  CalculationScales - DocumentTabularSection.ConditionsOfCustomerRebates.CalculationScales
//               - DocumentTabularSection.ConditionsOfVendorRebates.CalculationScales
//  CalculationScaleType - Number
//  KindAttributes - Structure:
//  	* GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods
//
Procedure ClearCalculationScales(CalculationScales, CalculationScaleType, KindAttributes) Export
	
	If KindAttributes.GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
	 Or CalculationScaleType = 0 Then
		
		CalculationScales.Clear();
	
	ElsIf CalculationScaleType = 1 Then // Progressive Scale
		
		For Each ScaleLine In CalculationScales Do
			
			ScaleLine.RangeBy = 0;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Parameters:
//  Form - See Document.ConditionsOfCustomerRebates.Form.DocumentForm
//        - See Document.ConditionsOfVendorRebates.Form.DocumentForm
//  TableName - String - Name of the table to be processed
//
Procedure InitializeProgressiveScale(Form, TableName) Export
	
	Goods = Form.Object[TableName]; // FormDataCollection
	FieldNameQuantity = "CountPlan";
	FieldNameQuantityBorder = "QuantityPlanRangeBound";
	
	LinesToDelete = New Array; // Array of FormDataCollectionItem
	
	For Each RowOfGoods In Goods Do
		
		If RowOfGoods[FieldNameQuantity] = 0 Then
			
			LinesToDelete.Add(RowOfGoods);
			
		Else
			
			RowOfGoods[FieldNameQuantityBorder] = 0;
			
		EndIf;
		
	EndDo;
	
	TMCommonUse.DeleteTableRows(Goods, LinesToDelete);
	
EndProcedure

// Returns:
//  Structure - Parameters For Checking Goods Periods By Keys:
// * GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods - 
// * ConditionFrequency - EnumRef.RebatesFrequencies - 
// * ValidOnDate - Date - 
// * ValidTo - Date - 
// * TablePresentation - String -
// * CalculationScaleType - Number -
// 
Function ParametersForCheckingPeriodsByKeys() Export
	
	Parameters = New Structure;
	Parameters.Insert("GoodsIndicator", Enums.TargetSalesIndicatorsOfRebatesByGoods.EmptyRef());
	Parameters.Insert("ConditionFrequency", Enums.RebatesFrequencies.EmptyRef());
	Parameters.Insert("ValidOnDate", Date(1, 1 ,1 ));
	Parameters.Insert("ValidTo", Date(1, 1 ,1 ));
	Parameters.Insert("TablePresentation", "");
	Parameters.Insert("CalculationScaleType", 0);
	
	Return Parameters;
	
EndFunction

// Parameters:
//  DataTable - DocumentTabularSection.ConditionsOfCustomerRebates.Goods
//                - DocumentTabularSection.ConditionsOfVendorRebates.Goods
//  CheckParameters - See ParametersForCheckingPeriodsByKeys
//  Cancel - Boolean -
//
Procedure CheckGoodsPeriodsByKey(DataTable, CheckParameters, Cancel) Export
	
	TableName = "Goods";
	Data = GoodsPeriodDataByKey(DataTable, CheckParameters);
	
	If GetFunctionalOption("UseItemVariants") Then
		
		MessageTemplatePeriods = NStr("vi = 'Trong danh sách ""%1"" các kỳ hiệu lực theo trường chính là ""Mặt hàng, Đặc tính"" bị giao nhau (%2)';
										|ru = 'В списке ""%1"" пересекаются периоды действия по ключевым полям ""Номенклатура, Характеристика"" (%2)';
										|en = 'In the ""%1"" list, validity periods for the ""Item, Variant"" key fields (%2) overlap'; fa = 'In the ""%1"" list, validity periods for the ""Item, Variant"" key fields (%2) overlap';
										|it = 'В списке ""%1"" пересекаются периоды действия по ключевым полям ""Номенклатура, Характеристика"" (%2)';
										|pl = 'In the ""%1"" list, validity periods for the ""Item, Variant"" key fields (%2) overlap';
										|tr = '""%1"" listesinde, ""Öğeler"" anahtar alanı için işlem süreleri çakışıyor (%2)'");
		MessageTemplatePeriodsEntirePeriod = NStr("vi = 'Trong danh sách ""%1"" đã chỉ định các kỳ hiệu lực khác nhau theo trường khóa ""Mặt hàng, Đặc tính"" (%2). Đối với chu kỳ điều kiện ""Toàn bộ kỳ"" không cho phép có các kỳ khác nhau.';
													|ru = 'В списке ""%1"" указаны разные периоды действия по ключевым полям ""Номенклатура, Характеристика"" (%2). Для периодичности условий ""Весь период"" наличие разных периодов не допускается.';
													|en = 'In the ""%1"" list, different validity periods are specified for the ""Item, Variant"" key fields (%2). Different periods are not allowed for the ""Whole period"" condition frequency.'; fa = 'In the ""%1"" list, different validity periods are specified for the ""Item, Variant"" key fields (%2). Different periods are not allowed for the ""Whole period"" condition frequency.';
													|it = 'In the ""%1"" list, different validity periods are specified for the ""Item, Variant"" key fields (%2). Different periods are not allowed for the ""Whole period"" condition frequency.';
													|pl = 'In the ""%1"" list, different validity periods are specified for the ""Item, Variant"" key fields (%2). Different periods are not allowed for the ""Whole period"" condition frequency.';
													|tr = '""%1"" listesinde, ""Ürün, Varyant"" (%2) anahtar alanları için farklı geçerlilik süreleri belirtilmektedir. ""Tüm dönem"" koşullarının dönemselliği nedeniyle, farklı dönemlerin mevcudiyetine izin verilmemektedir.'");
		MessageTemplateDuplicatesOfPercentagePlan = NStr("vi = 'Trong danh sách ""%1"" bị trùng các chỉ tiêu ""Số lượng, kế hoạch và/hoặc Thưởng, %"" theo các trường chính là ""Mặt hàng, Đặc tính"" (%2)';
														|ru = 'В списке ""%1"" дублируются показатели ""Кол-во, план и/или Бонус, %"" по ключевым полям ""Номенклатура, Характеристика"" (%2)';
														|en = 'In the ""%1"" list, the ""Quantity, plan and/or Rebate, %"" indicators for the ""Item, Variant"" key fields (%2) are duplicated'; fa = 'In the ""%1"" list, the ""Quantity, plan and/or Rebate, %"" indicators for the ""Item, Variant"" key fields (%2) are duplicated';
														|it = 'В списке ""%1"" дублируются показатели ""Кол-во, план и/или Бонус, %"" по ключевым полям ""Номенклатура, Характеристика"" (%2)';
														|pl = 'In the ""%1"" list, the ""Quantity, plan and/or Rebate, %"" indicators for the ""Item, Variant"" key fields (%2) are duplicated';
														|tr = '""%1"" listesinde, ""Öğeler, Özellik"" (%2) anahtar alanları için ""Miktar, plan ve/veya Bonus, %"" göstergeleri duplike olmuş'");
		MessageTemplateDuplicatesOfRanges = NStr("vi = 'Trong danh sách ""%1"" bị trùng các chỉ tiêu ""Số lượng, kế hoạch"" (%2) theo trường chính là  ""Mặt hàng, Đặc tính"" (%3)';
												|ru = 'В списке ""%1"" дублируются показатели ""Кол-во, план"" (%2) по ключевым полям ""Номенклатура, Характеристика"" (%3)';
												|en = 'In the ""%1"" list, the ""Quantity, plan"" indicators (%2) for the ""Item, Variant"" key fields (%3) are duplicated'; fa = 'In the ""%1"" list, the ""Quantity, plan"" indicators (%2) for the ""Item, Variant"" key fields (%3) are duplicated';
												|it = 'In the ""%1"" list, the ""Quantity, plan"" indicators (%2) for the ""Item, Variant"" key fields (%3) are duplicated';
												|pl = 'In the ""%1"" list, the ""Quantity, plan"" indicators (%2) for the ""Item, Variant"" key fields (%3) are duplicated';
												|tr = '""%1"" listesinde ""Miktar, plan"" (%2) göstergeleri ""Öğe, Özellik"" (%3) anahtar alanları için çoğaltılıyor'");
		
	Else
		
		MessageTemplatePeriods = NStr("vi = 'Trong danh sách ""%1"" các kỳ hiệu lực theo trường chính là ""Mặt hàng"" bị giao nhau (%2)';
										|ru = 'В списке ""%1"" пересекаются периоды действия по ключевому полю ""Номенклатура"" (%2)';
										|en = 'In the ""%1"" list, validity periods for the ""Items"" key field (%2) overlap'; fa = 'In the ""%1"" list, validity periods for the ""Items"" key field (%2) overlap';
										|it = 'В списке ""%1"" пересекаются периоды действия по ключевому полю ""Номенклатура"" (%2)';
										|pl = 'In the ""%1"" list, validity periods for the ""Items"" key field (%2) overlap';
										|tr = '""%1"" listesinde, ""Öğeler"" anahtar alanı için işlem süreleri çakışıyor (%2)'");
		MessageTemplatePeriodsEntirePeriod = NStr("vi = 'Trong danh sách ""%1"" đã chỉ định các kỳ hiệu lực khác nhau theo trường khóa ""Mặt hàng"" (%2). Đối với chu kỳ điều kiện ""Toàn bộ kỳ"" không cho phép có các kỳ khác nhau.';
													|ru = 'В списке ""%1"" указаны разные периоды действия по ключевому полю ""Номенклатура"" (%2). Для периодичности условий ""Весь период"" наличие разных периодов не допускается.';
													|en = 'In the ""%1"" list, different validity periods are specified for the ""Item"" key field (%2). Different periods are not allowed for the ""Whole period"" condition frequency.'; fa = 'In the ""%1"" list, different validity periods are specified for the ""Item"" key field (%2). Different periods are not allowed for the ""Whole period"" condition frequency.';
													|it = 'In the ""%1"" list, different validity periods are specified for the ""Item"" key field (%2). Different periods are not allowed for the ""Whole period"" condition frequency.';
													|pl = 'In the ""%1"" list, different validity periods are specified for the ""Item"" key field (%2). Different periods are not allowed for the ""Whole period"" condition frequency.';
													|tr = '""%1"" listesinde, ""Ürün, Varyant"" (%2) anahtar alanı için farklı geçerlilik süreleri belirtilmektedir. ""Tüm dönem"" koşullarının dönemselliği nedeniyle, farklı dönemlerin mevcudiyetine izin verilmemektedir.'");
		MessageTemplateDuplicatesOfPercentagePlan = NStr("vi = 'Trong danh sách ""%1"" bị trùng các chỉ tiêu ""Số lượng, kế hoạch và/hoặc Thưởng, %"" theo trường chính là ""Mặt hàng"" (%2)';
														|ru = 'В списке ""%1"" дублируются показатели ""Кол-во, план и/или Бонус, %"" по ключевому полю ""Номенклатура"" (%2)';
														|en = 'In the ""%1"" list, the ""Quantity, plan and/or Rebate, %"" indicators for the ""Item"" key field (%2) are duplicated'; fa = 'In the ""%1"" list, the ""Quantity, plan and/or Rebate, %"" indicators for the ""Item"" key field (%2) are duplicated';
														|it = 'В списке ""%1"" дублируются показатели ""Кол-во, план и/или Бонус, %"" по ключевому полю ""Номенклатура"" (%2)';
														|pl = 'In the ""%1"" list, the ""Quantity, plan and/or Rebate, %"" indicators for the ""Item"" key field (%2) are duplicated';
														|tr = '""%1"" listesinde, ""Öğeler"" (%2) anahtar alanları için ""Miktar, plan ve/veya Bonus, %"" göstergeleri duplike olmuş'");
		MessageTemplateDuplicatesOfRanges = NStr("vi = 'Trong danh sách ""%1"" bị trùng các chỉ tiêu ""Số lượng, kế hoạch"" (%2) theo trường chính là ""Mặt hàng"" (%3)';
												|ru = 'В списке ""%1"" дублируются показатели ""Кол-во, план"" (%2) по ключевому полю ""Номенклатура"" (%3)';
												|en = 'In the ""%1"" list, the ""Quantity, plan"" (%2) indicators for the ""Item"" key field (%3) are duplicated'; fa = 'In the ""%1"" list, the ""Quantity, plan"" (%2) indicators for the ""Item"" key field (%3) are duplicated';
												|it = 'In the ""%1"" list, the ""Quantity, plan"" (%2) indicators for the ""Item"" key field (%3) are duplicated';
												|pl = 'In the ""%1"" list, the ""Quantity, plan"" (%2) indicators for the ""Item"" key field (%3) are duplicated';
												|tr = '""%1"" listesinde ""Miktar, plan"" (%2) göstergeleri, ""Öğe"" (%3) anahtar alanı kapsamında kopyalanmaktadır'");
		
	EndIf;
	
	While Data.IntersectionsOfPeriods.Next() Do
		
		If CheckParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Count
		   And CheckParameters.ConditionFrequency = Enums.RebatesFrequencies.WholePeriod Then
			TemplatePeriods = MessageTemplatePeriodsEntirePeriod;
		Else
			TemplatePeriods = MessageTemplatePeriods;
		EndIf;
		
		ProductPresentation = ProductsClientServer.ProductPresentation(
			Data.IntersectionsOfPeriods.Products,
			Data.IntersectionsOfPeriods.Characteristic);
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			TemplatePeriods,
			CheckParameters.TablePresentation,
			ProductPresentation);
			
		PathToField = CommonClientServer.PathToTabularSection(
			TableName, Data.IntersectionsOfPeriods.FirstRow, "LineNumber");
		Common.MessageToUser(MessageText,, PathToField, "Object", Cancel);
		
	EndDo;
	
	While Data.DuplicatesOfPercentagePlan.Next() Do
		
		ProductPresentation = ProductsClientServer.ProductPresentation(
			Data.DuplicatesOfPercentagePlan.Products,
			Data.DuplicatesOfPercentagePlan.Characteristic);
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplateDuplicatesOfPercentagePlan,
			CheckParameters.TablePresentation,
			ProductPresentation);
			
		PathToField = CommonClientServer.PathToTabularSection(
			TableName, Data.DuplicatesOfPercentagePlan.FirstRow, "LineNumber");
		Common.MessageToUser(MessageText,, PathToField, "Object", Cancel);
		
	EndDo;
	
	While Data.DuplicatesByRanges.Next() Do
		
		ProductPresentation = ProductsClientServer.ProductPresentation(
			Data.DuplicatesByRanges.Products,
			Data.DuplicatesByRanges.Characteristic);
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplateDuplicatesOfRanges,
			CheckParameters.TablePresentation,
			Format(Data.DuplicatesByRanges.CountPlan, "NFD=3"),
			ProductPresentation);
			
		PathToField = CommonClientServer.PathToTabularSection(
			TableName, Data.DuplicatesByRanges.FirstRow, "CountPlan");
		Common.MessageToUser(MessageText,, PathToField, "Object", Cancel);
		
	EndDo;
	
EndProcedure

// Parameters:
//  DataTable - DocumentTabularSection.ConditionsOfCustomerRebates.ProductProperties_
//                - DocumentTabularSection.ConditionsOfVendorRebates.ProductProperties_
//  CheckParameters - See ParametersForCheckingPeriodsByKeys
//  Cancel - Boolean -
//
Procedure CheckPeriodsOfItemPropertiesByKey(DataTable, CheckParameters, Cancel) Export
	
	TableName = "ProductProperties_";
	Data = DataForPeriodsOfItemPropertiesByKey(DataTable, CheckParameters);
	
	MessageTemplatePeriods = NStr("vi = 'Trong danh sách ""%1"" các kỳ hiệu lực bị giao nhau theo giá trị thuộc tính ""%2""';
									|ru = 'В списке ""%1"" пересекаются периоды действия по значению свойства ""%2""';
									|en = 'In the ""%1"" list, validity periods for the ""%2"" property value overlap'; fa = 'In the ""%1"" list, validity periods for the ""%2"" property value overlap';
									|it = 'In the ""%1"" list, validity periods for the ""%2"" property value overlap';
									|pl = 'In the ""%1"" list, validity periods for the ""%2"" property value overlap';
									|tr = '""%1"" listesinde, ""%2"" özelliğinin değeri için işlem süreleri çakışmaktadır'");
	MessageTemplatePeriodsEntirePeriod = NStr("vi = 'Trong danh sách ""%1"" có chỉ định các kỳ hiệu lực khác nhau theo giá trị thuộc tính ""%2"". Đối với chu kỳ điều kiện ""Toàn bộ kỳ"" không cho phép có các kỳ khác nhau.';
												|ru = 'В списке ""%1"" указаны разные периоды действия по значению свойства ""%2"". Для периодичности условий ""Весь период"" наличие разных периодов не допускается.';
												|en = 'In the ""%1"" list, different validity periods are specified for the ""%2"" property value. Different periods are not allowed for the ""Whole period"" condition frequency.'; fa = 'In the ""%1"" list, different validity periods are specified for the ""%2"" property value. Different periods are not allowed for the ""Whole period"" condition frequency.';
												|it = 'In the ""%1"" list, different validity periods are specified for the ""%2"" property value. Different periods are not allowed for the ""Whole period"" condition frequency.';
												|pl = 'In the ""%1"" list, different validity periods are specified for the ""%2"" property value. Different periods are not allowed for the ""Whole period"" condition frequency.';
												|tr = '""%1"" listesinde, ""%2"" özelliğinin değeri kapsamında farklı geçerlilik süreleri belirtilmektedir. ""Tüm dönem"" koşullarının dönemselliği nedeniyle, farklı dönemlerin mevcudiyetine izin verilmemektedir.'");
	MessageTemplateDuplicatesOfPercentagePlan = NStr("vi = 'Trong danh sách ""%1"" bị trùng các chỉ tiêu ""Số lượng kế hoạch và/hoặc Thưởng, %"" theo giá trị thuộc tính ""%2""';
													|ru = 'В списке ""%1"" дублируются показатели ""Кол-во, план и/или Бонус, %"" по значению свойства ""%2""';
													|en = 'In the ""%1"" list, the ""Quantity, plan and/or Rebate, %"" indicators for the ""%2"" property value are duplicated'; fa = 'In the ""%1"" list, the ""Quantity, plan and/or Rebate, %"" indicators for the ""%2"" property value are duplicated';
													|it = 'In the ""%1"" list, the ""Quantity, plan and/or Rebate, %"" indicators for the ""%2"" property value are duplicated';
													|pl = 'In the ""%1"" list, the ""Quantity, plan and/or Rebate, %"" indicators for the ""%2"" property value are duplicated';
													|tr = '""%1"" listesinde, ""%2"" özelliğinin değeri için ""Miktar, plan ve/veya Bonus, %"" göstergeleri kopyalanmaktadır'");
	MessageTemplateDuplicatesOfRanges = NStr("vi = 'Trong danh sách ""%1"" bị trùng các chỉ tiêu ""Số lượng, kế hoạch"" (%2) theo giá trị thuộc tính ""%3""';
											|ru = 'В списке ""%1"" дублируются показатели ""Кол-во, план"" (%2) по значению свойства ""%3""';
											|en = 'In the ""%1"" list, the ""Quantity, plan"" indicators (%2) for the ""%3"" property value are duplicated'; fa = 'In the ""%1"" list, the ""Quantity, plan"" indicators (%2) for the ""%3"" property value are duplicated';
											|it = 'In the ""%1"" list, the ""Quantity, plan"" indicators (%2) for the ""%3"" property value are duplicated';
											|pl = 'In the ""%1"" list, the ""Quantity, plan"" indicators (%2) for the ""%3"" property value are duplicated';
											|tr = '""%1"" listesinde, ""%3"" özelliğinin değeri için ""Miktar, plan"" (%2) göstergeleri kopyalanmaktadır'");
	
	While Data.IntersectionsOfPeriods.Next() Do
		
		If CheckParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Count
		   And CheckParameters.ConditionFrequency = Enums.RebatesFrequencies.WholePeriod Then
			TemplatePeriods = MessageTemplatePeriodsEntirePeriod;
		Else
			TemplatePeriods = MessageTemplatePeriods;
		EndIf;
		
		FieldPresentation = TrimAll(Data.IntersectionsOfPeriods.PropertyValue);
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			TemplatePeriods,
			CheckParameters.TablePresentation,
			FieldPresentation);
			
		PathToField = CommonClientServer.PathToTabularSection(
			TableName, Data.IntersectionsOfPeriods.FirstRow, "LineNumber");
		Common.MessageToUser(MessageText,, PathToField, "Object", Cancel);
		
	EndDo;
	
	While Data.DuplicatesOfPercentagePlan.Next() Do
		
		FieldPresentation = TrimAll(Data.DuplicatesOfPercentagePlan.PropertyValue);
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplateDuplicatesOfPercentagePlan,
			CheckParameters.TablePresentation,
			FieldPresentation);
			
		PathToField = CommonClientServer.PathToTabularSection(
			TableName, Data.DuplicatesOfPercentagePlan.FirstRow, "LineNumber");
		Common.MessageToUser(MessageText,, PathToField, "Object", Cancel);
		
	EndDo;
	
	While Data.DuplicatesByRanges.Next() Do
		
		FieldPresentation = TrimAll(Data.DuplicatesByRanges.PropertyValue);
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplateDuplicatesOfRanges,
			CheckParameters.TablePresentation,
			Format(Data.DuplicatesByRanges.CountPlan, "NFD=3"),
			FieldPresentation);
			
		PathToField = CommonClientServer.PathToTabularSection(
			TableName, Data.DuplicatesByRanges.FirstRow, "CountPlan");
		Common.MessageToUser(MessageText,, PathToField, "Object", Cancel);
		
	EndDo;
	
EndProcedure

// Returns the Query Text for creating a temporary table with products selected by the values of the specified property.
// 
// Parameters:
//  CalculationOfCustomerBonuses - Boolean -
//  PropertyName - String -
//  ItemItemPropertyLink - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo 
//  AccordingToDocument - Boolean
// 
// Returns:
//  String - Query text
//
Function QueryTextItemsByProperty(CalculationOfCustomerBonuses, PropertyName, ItemItemPropertyLink, AccordingToDocument = False) Export
	
	If Not ValueIsFilled(ItemItemPropertyLink) Then
		
		QueryText =
		"SELECT
		|	SourceTable1.TermDocument AS TermDocument,
		|	CatalogProducts.Ref AS Products,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
		|	SourceTable1.PropertyValue AS PropertyValue,
		|	SourceTable1.ValidOnDate AS ValidOnDate,
		|	SourceTable1.ValidTo AS ValidTo,
		|	SourceTable1.BasePrice AS BasePrice,
		|	SourceTable1.BonusPercent AS BonusPercent,
		|	SourceTable1.CountPlan AS CountPlan,
		|	SourceTable1.QuantityPlanRangeBound AS QuantityPlanRangeBound
		|INTO TT_ItemsByProperty
		|FROM
		|	&SourceTable1 AS SourceTable1
		|		INNER JOIN Catalog.Products AS CatalogProducts
		|		ON SourceTable1.PropertyValue = &ExpressionAttributeField
		|WHERE
		|	SourceTable1.TermDocument = &SourceDocument_
		|	AND &OutputCondition";
		
		ExpressionAttributeField = "CatalogProducts." + PropertyName;
		
		If AccordingToDocument Then
			
			If CalculationOfCustomerBonuses Then
				SourceTable1 = "Document.ConditionsOfCustomerRebates.ProductProperties_";
			Else
				SourceTable1 = "Document.ConditionsOfVendorRebates.ProductProperties_";
			EndIf;
			
			QueryText = StrReplace(QueryText, "&OutputCondition", "NOT SourceTable1.Canceled");
			QueryText = StrReplace(QueryText, "SourceTable1.TermDocument", "SourceTable1.Ref");
			QueryText = StrReplace(QueryText, "SourceTable1.BonusPercent", "SourceTable1.Percent");
			
		Else
			
			If CalculationOfCustomerBonuses Then
				SourceTable1 = "InformationRegister.CustomerRebatesItemProperties";
			Else
				SourceTable1 = "InformationRegister.VendorRebatesItemProperties";
			EndIf;
			
			QueryText = StrReplace(QueryText, "&OutputCondition", "TRUE");
			
		EndIf;
		
		QueryText = StrReplace(QueryText, "&ExpressionAttributeField", ExpressionAttributeField);
		QueryText = StrReplace(QueryText, "&SourceTable1", SourceTable1);
		
	Else
		
		QueryText =
		"SELECT
		|	SourceTable1.TermDocument AS TermDocument,
		|	ProductsAdditionalDetails.Ref AS Products,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
		|	SourceTable1.PropertyValue AS PropertyValue,
		|	SourceTable1.ValidOnDate AS ValidOnDate,
		|	SourceTable1.ValidTo AS ValidTo,
		|	SourceTable1.BasePrice AS BasePrice,
		|	SourceTable1.BonusPercent AS BonusPercent,
		|	SourceTable1.CountPlan AS CountPlan,
		|	SourceTable1.QuantityPlanRangeBound AS QuantityPlanRangeBound
		|INTO TT_ItemsByProperty
		|FROM
		|	&SourceTable1 AS SourceTable1
		|		INNER JOIN Catalog.Products.AdditionalAttributes AS ProductsAdditionalDetails
		|		ON &ProductItemProperty = ProductsAdditionalDetails.Property
		|			AND SourceTable1.PropertyValue = ProductsAdditionalDetails.Value
		|WHERE
		|	SourceTable1.TermDocument = &SourceDocument_
		|	AND &OutputCondition";
		
		If AccordingToDocument Then
			
			If CalculationOfCustomerBonuses Then
				SourceTable1 = "Document.ConditionsOfCustomerRebates.ProductProperties_";
			Else
				SourceTable1 = "Document.ConditionsOfVendorRebates.ProductProperties_";
			EndIf;
			
			QueryText = StrReplace(QueryText, "&OutputCondition", "NOT SourceTable1.Canceled");
			QueryText = StrReplace(QueryText, "SourceTable1.TermDocument", "SourceTable1.Ref");
			QueryText = StrReplace(QueryText, "SourceTable1.BonusPercent", "SourceTable1.Percent");
			
		Else
			
			If CalculationOfCustomerBonuses Then
				SourceTable1 = "InformationRegister.CustomerRebatesItemProperties";
			Else
				SourceTable1 = "InformationRegister.VendorRebatesItemProperties";
			EndIf;
			
			QueryText = StrReplace(QueryText, "&OutputCondition", "TRUE");
			
		EndIf;
		
		QueryText = StrReplace(QueryText, "&SourceTable1", SourceTable1);
		
	EndIf;
	
	Return QueryText;
	
EndFunction

// Parameters:
//  VerificationObject - DocumentObject.ConditionsOfCustomerRebates, DocumentObject.ConditionsOfVendorRebates -
//  TablePresentation - String - Presentation of the table part being checked
//  KindAttributes - Structure:
//  	* GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods
//  Cancel - Boolean - Refusal -
//
Procedure CheckIndicationOfEmptyCharacteristicValues(VerificationObject, TablePresentation, KindAttributes, Cancel) Export
	
	FilterOfProducts_ = VerificationObject.FilterOfProducts_;
	ConditionFrequency = VerificationObject.ConditionFrequency;
	PresentationOfKeyField = NStr("vi = 'Mặt hàng';
									|ru = 'Номенклатура';
									|en = 'Items'; fa = 'اقلام';
									|it = 'Articolo';
									|pl = 'Produkt';
									|tr = 'Öğe'");
	PresentationOfAuxiliaryField = NStr("vi = 'Đặc tính';
										|ru = 'Характеристика';
										|en = 'Variant'; fa = 'گونه';
										|it = 'Caratteristica';
										|pl = 'Charakterystyka';
										|tr = 'Varyant'");
	
	Selection = SelectionOfEmptyAndFilledCharacteristics(VerificationObject, KindAttributes);
	
	If FilterOfProducts_ = Enums.RebatesLists.ExceptForSelectedOnes Then
		
		MessageTemplate = NStr("vi = 'Trong danh sách ""%1"" theo trường khóa ""%2"" (%3) các dòng có (và không có) giá trị được điền trong trường ""%4""';
								|ru = 'В списке ""%1"" по ключевому полю ""%2"" (%3) есть строки с заполненным и незаполненным значением в поле ""%4""';
								|en = 'In the ""%1"" list for the ""%2"" (%3) key field, there are lines with a filled and unfilled value in the ""%4"" field'; fa = 'In the ""%1"" list for the ""%2"" (%3) key field, there are lines with a filled and unfilled value in the ""%4"" field';
								|it = 'In the ""%1"" list for the ""%2"" (%3) key field, there are lines with a filled and unfilled value in the ""%4"" field';
								|pl = 'In the ""%1"" list for the ""%2"" (%3) key field, there are lines with a filled and unfilled value in the ""%4"" field';
								|tr = '""%1"" listesinde ""%2"" (%3) anahtar alanı için ""%4"" alanında doldurulmuş ve doldurulmamış değere sahip satırlar mevcut'");
		
	ElsIf ConditionFrequency = Enums.RebatesFrequencies.WholePeriod
	   And KindAttributes.GoodsIndicator =  Enums.TargetSalesIndicatorsOfRebatesByGoods.Count Then
		
		MessageTemplate = NStr("vi = 'Trong danh sách ""%1"" theo trường khóa ""%2"" (%3) có các dòng có (và không có) giá trị được điền trong trường ""%4"". Đối với chu kỳ điều kiện ""%5"" không được phép có các dòng với cùng một mặt hàng mà đặc tính được điền ở dòng này và bỏ trống ở dòng khác.';
								|ru = 'В списке ""%1"" по ключевому полю ""%2"" (%3) есть строки с заполненным и незаполненным значением в поле ""%4"". Для периодичности условий ""%5"" наличие строк по одной номенклатуре с заполненной и не заполненной характеристиками не допускается.';
								|en = 'In the ""%1"" list for the ""%2"" (%3) key field, there are strings with a filled and unfilled value in the ""%4"" field. For frequency of the ""%5"" condition, the lines for one item with both filled and unfilled characteristics are not allowed.'; fa = 'In the ""%1"" list for the ""%2"" (%3) key field, there are strings with a filled and unfilled value in the ""%4"" field. For frequency of the ""%5"" condition, the lines for one item with both filled and unfilled characteristics are not allowed.';
								|it = 'In the ""%1"" list for the ""%2"" (%3) key field, there are strings with a filled and unfilled value in the ""%4"" field. For frequency of the ""%5"" condition, the lines for one item with both filled and unfilled characteristics are not allowed.';
								|pl = 'In the ""%1"" list for the ""%2"" (%3) key field, there are strings with a filled and unfilled value in the ""%4"" field. For frequency of the ""%5"" condition, the lines for one item with both filled and unfilled characteristics are not allowed.';
								|tr = '""%1"" listesinde, ""%2"" (%3) anahtar alanı kapsamında ""%4"" alanında doldurulmuş ve doldurulmamış değere sahip satırlar mevcut. ""%5"" koşullarının sıklığı nedeniyle, doldurulmuş ve doldurulmamış özelliklere sahip tek bir öğenin satırlarının bulunmasına izin verilmemektedir.'");
		
	Else
		
		MessageTemplate = NStr("vi = 'Trong danh sách ""%1"" theo trường khóa ""%2"" (%3) vào các kỳ giao nhau có các dòng có và không có giá trị được điền trong trường ""%4""';
								|ru = 'В списке ""%1"" по ключевому полю ""%2"" (%3) в пересекающихся периодах есть строки с заполненным и незаполненным значением в поле ""%4""';
								|en = 'In the ""%1"" list for the ""%2"" (%3) key field in overlapping periods, there are lines with filled and unfilled values in the ""%4"" field'; fa = 'In the ""%1"" list for the ""%2"" (%3) key field in overlapping periods, there are lines with filled and unfilled values in the ""%4"" field';
								|it = 'In the ""%1"" list for the ""%2"" (%3) key field in overlapping periods, there are lines with filled and unfilled values in the ""%4"" field';
								|pl = 'In the ""%1"" list for the ""%2"" (%3) key field in overlapping periods, there are lines with filled and unfilled values in the ""%4"" field';
								|tr = '""%1"" listesinde, ""%2"" (%3) anahtar alanına göre kesişen dönemlerde ""%4"" alanında doldurulmuş ve doldurulmamış değere sahip satırlar mevcut'");
		
	EndIf;
	
	While Selection.Next() Do
		
		PathToField = CommonClientServer.PathToTabularSection(
			"Goods", Selection.LineNumber, "LineNumber");
			
		If ConditionFrequency = Enums.RebatesFrequencies.WholePeriod
		   And KindAttributes.GoodsIndicator =  Enums.TargetSalesIndicatorsOfRebatesByGoods.Count Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate,
				TablePresentation,
				PresentationOfKeyField,
				String(Selection.Products),
				PresentationOfAuxiliaryField,
				String(ConditionFrequency));
			
		Else
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate,
				TablePresentation,
				PresentationOfKeyField,
				String(Selection.Products),
				PresentationOfAuxiliaryField);
			
		EndIf;
		
		Common.MessageToUser(MessageText,, PathToField, "Object", Cancel);
		
	EndDo;
	
EndProcedure

// Parameters:
//  Form - See Catalog.VendorRebateKinds.Form.ItemForm
//        - See Catalog.CustomerRebatesKinds.Form.ItemForm
//
Procedure FillInListOfOperandsOfNomenclature(Form) Export
	
	Items = Form.Items;
	ProductProperties_ = Form.ProductProperties_;
	OperandTreeOfNomenclature = GetTreeOfOperandsOfNomenclature();
	
	UseAdditionalAttributesAndInfo =
		GetFunctionalOption("UseAdditionalAttributesAndInfo");
	ItemsTypes = ProcessingOfFormulas.TypesOfOperandTreeElements();
	TypesOfItemProperties = Metadata.DefinedTypes.RebateItemPropertyTypes.Type;
	ObjectMetadata = Metadata.Catalogs.Products;
	StandardObjectDetails = ObjectMetadata.StandardAttributes;
	ObjectAttributes = ObjectMetadata.Attributes;
	CommonAttributes = Metadata.CommonAttributes;
	
	For Each CurrentTreeRow In OperandTreeOfNomenclature.Rows Do
		
		SkipLine =
			(CurrentTreeRow.DeletionMark
			Or Not AllowedValueTypeForItemProperty(CurrentTreeRow.ValueType, TypesOfItemProperties)
			Or CurrentTreeRow.TreeItemType = ItemsTypes.AdditionalInfoItem
			Or (Not UseAdditionalAttributesAndInfo
				And CurrentTreeRow.TreeItemType = ItemsTypes.AdditionalAttribute));
		
		IDOfAttribute = CurrentTreeRow.Id;
		ThisIsAdditionalAttributeProperty = (StrFind(IDOfAttribute, "{") > 0);
		
		If Not ThisIsAdditionalAttributeProperty
		   And Not SkipLine
		   And Not Common.IsStandardAttribute(StandardObjectDetails, IDOfAttribute) Then
			
			MetadataObject = ObjectAttributes.Find(IDOfAttribute);
			If MetadataObject = Undefined Then
				
				MetadataObject = CommonAttributes.Find(IDOfAttribute);
				If MetadataObject <> Undefined Then
					SkipLine = True;
				EndIf;
				
			Else
				
				SkipLine = Not Common.MetadataObjectAvailableByFunctionalOptions(MetadataObject);
				
			EndIf;
			
		EndIf;
		
		If SkipLine Then
			Continue;
		EndIf;
		
		Presentation = CurrentTreeRow.Presentation;
		Items.ProductItemProperty.ChoiceList.Add(IDOfAttribute, Presentation);
		
		If Not ThisIsAdditionalAttributeProperty Then
			ProductProperties_.Add(IDOfAttribute, Presentation);
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  IDOfAttribute - String
// Returns:
// See ItemAttributeData
//
Function ItemPropertyVerificationData(Val IDOfAttribute) Export
	
	Result = ItemAttributeData();
	
	If Not ValueIsFilled(IDOfAttribute) Then
		Return Result;
	EndIf;
	
	SetPrivilegedMode(True);
	
	ThisIsAdditionalAttributeProperty = (StrFind(IDOfAttribute, "{") > 0);
	
	If ThisIsAdditionalAttributeProperty Then
		
		CheckResult = IsAdditionalAttributeOfItem(IDOfAttribute);
		FillPropertyValues(Result, CheckResult);
		
	ElsIf IsItemAttribute(IDOfAttribute) Then
		
		Result.Is_Attribute = True;
		ObjectMetadata = Metadata.Catalogs.Products;
		
		If Common.IsStandardAttribute(ObjectMetadata.StandardAttributes, IDOfAttribute) Then
			
			Result.ValueType = ObjectMetadata.StandardAttributes[IDOfAttribute].Type;
			Result.Title = ObjectMetadata.StandardAttributes[IDOfAttribute].Presentation();
			
		Else
			
			Result.ValueType = ObjectMetadata.Attributes[IDOfAttribute].Type;
			Result.Title = ObjectMetadata.Attributes[IDOfAttribute].Presentation();
			
			MetadataObject = ObjectMetadata.Attributes[IDOfAttribute];
			Result.AvailableByFunctionalOptions =
				Common.MetadataObjectAvailableByFunctionalOptions(MetadataObject);
			
		EndIf;
		
		Result.AllowedValueType = AllowedValueTypeForItemProperty(Result.ValueType);
		Result.AllowedToUse = (Result.AllowedValueType
											And Result.AvailableByFunctionalOptions);
	Else
		
		Result.AttributeNotFound = True;
		Result.Title = IDOfAttribute;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  IDOfAttribute - String
//  ContentOfGoods - EnumRef.RebatesItems
//  Cancel - Boolean
//
Procedure ControlPropertiesOfNomenclatureOfRebateKind(Val IDOfAttribute, Val ContentOfGoods, Cancel) Export
	
	If ContentOfGoods <> Enums.RebatesItems.ProductItemProperty
	   And IsBlankString(IDOfAttribute) Then
		Return;
	EndIf;
	
	CheckResult = ItemPropertyVerificationData(IDOfAttribute);
	
	If Not CheckResult.AllowedToUse Then
		
		DescriptionOfReasonForBan = DescriptionOfReasonForBanItemProperties(CheckResult);
		MessageText = DescriptionOfReasonForBan.MessageText;
		Common.MessageToUser(MessageText,, "ProductItemProperty", "Object", Cancel);
		
	EndIf;
	
EndProcedure

// Parameters:
//  Document - DocumentRef.ConditionsOfCustomerRebates, DocumentRef.ConditionsOfVendorRebates -
//  TermsAndConditionsAttributes -QueryResultSelection:
//   * ContentOfGoods - EnumRef.RebatesItems
//   * ProductItemProperty - String
//  Cancel - Boolean
// 
Procedure CheckRebateKindOfTermsAndConditionsDocument(Document, TermsAndConditionsAttributes, Cancel = False) Export
	
	ContentOfGoods = TermsAndConditionsAttributes.ContentOfGoods;
	IDOfAttribute = TermsAndConditionsAttributes.ProductItemProperty;
	
	If ContentOfGoods = Enums.RebatesItems.ProductItemProperty Then
		
		CheckResult = ItemPropertyVerificationData(IDOfAttribute);
		If Not CheckResult.AllowedToUse Then
			
			FieldName = "TermDocument";
			ReportItemPropertiesError(CheckResult, FieldName, Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//  CheckResult - See ItemAttributeData
//  FieldName - String
//  Cancel - Boolean
// 
Procedure ReportItemPropertiesError(Val CheckResult, Val FieldName, Cancel = False) Export
	
	DescriptionOfReasonForBan = DescriptionOfReasonForBanItemProperties(CheckResult);
	TextOfMessageIsBeginning = DescriptionOfReasonForBan.MessageText;
	MessageTextEnd = NStr("vi = 'Hãy kiểm tra tùy chỉnh dạng thưởng lũy kế.';
							|ru = 'Проверьте настройки вида ретро-бонусов.';
							|en = 'Check the rebates kind settings.'; fa = 'Check the rebates kind settings.';
							|it = 'Check the rebates kind settings.';
							|pl = 'Check the rebates kind settings.';
							|tr = 'Retro bonusların türünün ayarlarını kontrol edin.'");
	MessageText = TextOfMessageIsBeginning + " " + MessageTextEnd;
	
	Common.MessageToUser(MessageText,, FieldName, "Object", Cancel);
	
EndProcedure

// Parameters:
//  CheckResult - See ItemAttributeData
//  RebateKindIsUsed - Boolean
// 
// Returns:
//  Structure:
//   * ShortDescription - String
//   * DetailedDescription - String
//   * MessageText - String
//
Function DescriptionOfReasonForBanItemProperties(Val CheckResult, Val RebateKindIsUsed = False) Export
	
	ProhibitionReason = New Structure;
	ProhibitionReason.Insert("ShortDescription", "");
	ProhibitionReason.Insert("DetailedDescription", "");
	ProhibitionReason.Insert("MessageText", "");
	
	If CheckResult.AllowedToUse Then
		
		Return ProhibitionReason;
		
	EndIf;
	
	If CheckResult.AdditionalAttribute Then
		
		ReasonForBanForAdditionalAttributes(ProhibitionReason, CheckResult, RebateKindIsUsed);
		
	Else
		
		ReasonForBanForAttribute(ProhibitionReason, CheckResult, RebateKindIsUsed);
		
	EndIf;
	
	Return ProhibitionReason;
	
EndFunction

// Parameters:
//  ValueType - TypeDescription
//  TypesOfItemProperties - TypeDescription
// Returns:
// Boolean
//
Function AllowedValueTypeForItemProperty(ValueType, TypesOfItemProperties = Undefined) Export
	
	Result = False;
	
	If TypesOfItemProperties = Undefined Then
		TypesOfItemProperties = Metadata.DefinedTypes.RebateItemPropertyTypes.Type;
	EndIf;
	
	TypesArray = ValueType.Types();
	For Each Current_ValueType In TypesArray Do
		
		If TypesOfItemProperties.ContainsType(Current_ValueType) Then
			
			Result = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Parameters:
//  ValueType - TypeDescription
// Returns:
// TypeDescription
//
Function AllowedValueTypesItemProperties(ValueType) Export
	
	ArrayOfPassedTypes = ValueType.Types();
	TypesArray = New Array; // Array of Type
	TypeDescription = Metadata.DefinedTypes.RebateItemPropertyTypes.Type;
	
	For Each Current_ValueType In ArrayOfPassedTypes Do
		
		If TypeDescription.ContainsType(Current_ValueType) Then
			
			TypesArray.Add(Current_ValueType);
			
		EndIf;
		
	EndDo;
	
	NumberQualifiers = ValueType.NumberQualifiers;
	StringQualifiers = ValueType.StringQualifiers;
	DateQualifiers = ValueType.DateQualifiers;
	BinaryDataQualifiers = ValueType.BinaryDataQualifiers;
	
	Return New TypeDescription(
		TypesArray,
		,
		,
		NumberQualifiers,
		StringQualifiers,
		DateQualifiers,
		BinaryDataQualifiers);
	
EndFunction

#EndRegion

#Region CommonMethodsByRanges

// Updates the field in TS based on the change made for all rows related to the range
//
// Parameters:
//  Table - TabularSection, FormDataCollection -
//  FilterParameters - Structure
//  Value - Arbitrary -
//  FieldName - String -
//  ExceptOriginal - Boolean - 
//
Procedure UpdateSelectionTableField(Table, FilterParameters, Value, FieldName, ExceptOriginal = False) Export
	
	FieldNameSourceString = "InitialString";
	
	Rows_To_Change = Table.FindRows(FilterParameters);
	For Each TableRow In Rows_To_Change Do
		
		If ExceptOriginal
		   And TableRow[FieldNameSourceString] Then
			Continue;
		EndIf;
		TableRow[FieldName] = Value;
		
	EndDo;
	
EndProcedure

// Parameters:
//  ProcessedTable - FormDataCollection, ValueTable -
//  CorrectionTable - ValueTable - Table with data for correction
//  FilterParameters - Structure - Structure for selecting the data of the processed table
// 
Procedure UpdateRowRangeDesignation(ProcessedTable, CorrectionTable, FilterParameters) Export
	
	DesignationOfIntervalUpTo = NStr("vi = '≤ %1';
									|ru = '≤ %1';
									|en = '≤ %1'; fa = '≤ %1';
									|it = '≤ %1';
									|pl = '≤ %1';
									|tr = '≤ %1'");
	DesignationOfIntervalFromTo = NStr("vi = '> %1 và ≤ %2';
										|ru = '> %1 и ≤ %2';
										|en = '> %1 and ≤ %2'; fa = '> %1 and ≤ %2';
										|it = '> %1 and ≤ %2';
										|pl = '> %1 and ≤ %2';
										|tr = '> %1 ve ≤ %2'");
	DesignationOfIntervalOver = NStr("vi = '> %1';
									|ru = '> %1';
									|en = '> %1'; fa = '> %1';
									|it = '> %1';
									|pl = '> %1';
									|tr = '> %1'");
		
	For Each CorrectionLine In CorrectionTable Do
		
		FillPropertyValues(FilterParameters, CorrectionLine);
		If TypeOf(ProcessedTable) = Type("ValueTable") Then
			
			TempTable = ProcessedTable.Copy(FilterParameters);
			
		Else
			
			FoundRows = ProcessedTable.FindRows(FilterParameters);
			TempTable = ProcessedTable.Unload(FoundRows);
			
		EndIf;
		
		TempTable.Sort("CountPlan");
		NumberOfIntervals_ = TempTable.Count();
		
		If NumberOfIntervals_ = 0 Then
			
			Continue;
			
		ElsIf TempTable[0].CountPlan <> 0 Then
			
			RangeDesignation = NStr("vi = 'Không có khoảng có giá trị 0';
									|ru = 'Нет диапазона со значением 0';
									|en = 'There is no range with the 0 value'; fa = 'There is no range with the 0 value';
									|it = 'There is no range with the 0 value';
									|pl = 'There is no range with the 0 value';
									|tr = '0 değerinde bir aralık yok'");
			For Each ProductTableRow_ In TempTable Do
				
				FillString = ProcessedTable[ProductTableRow_.LineNumber - 1];
				FillString.RangeDesignation = RangeDesignation;
				
			EndDo;
			
		ElsIf NumberOfIntervals_ = 1 Then
			
			FirstInterval = TempTable[0];
			
			IntervalEndpoint = RebatesClientServer.FormatOfIntervalBoundary(FirstInterval.CountPlan);
			RangeDesignation = StringFunctionsClientServer.SubstituteParametersToString(
				DesignationOfIntervalOver,
				IntervalEndpoint);
			
			FillString = ProcessedTable[FirstInterval.LineNumber - 1];
			FillString.RangeDesignation = RangeDesignation;
			FillString.QuantityPlanRangeBound = 0;
			
		ElsIf NumberOfIntervals_ > 1 Then
			
			FirstInterval = TempTable[0];
			SecondInterval = TempTable[1];
			
			IntervalEndpoint = RebatesClientServer.FormatOfIntervalBoundary(SecondInterval.CountPlan);
			RangeDesignation = StringFunctionsClientServer.SubstituteParametersToString(
				DesignationOfIntervalUpTo,
				IntervalEndpoint);
			
			FillString = ProcessedTable[FirstInterval.LineNumber - 1];
			FillString.RangeDesignation = RangeDesignation;
			FillString.QuantityPlanRangeBound = SecondInterval.CountPlan;
			
			For CurIndex__ = 1 To NumberOfIntervals_ - 2 Do
				
				ThisInterval = TempTable[CurIndex__];
				NextInterval_ = TempTable[CurIndex__ + 1];
				
				BoundaryOfIntervalFrom = RebatesClientServer.FormatOfIntervalBoundary(ThisInterval.CountPlan);
				BoundaryOfIntervalTo = RebatesClientServer.FormatOfIntervalBoundary(NextInterval_.CountPlan);
				RangeDesignation = StringFunctionsClientServer.SubstituteParametersToString(
					DesignationOfIntervalFromTo,
					BoundaryOfIntervalFrom,
					BoundaryOfIntervalTo);
				
				FillString = ProcessedTable[ThisInterval.LineNumber - 1];
				FillString.RangeDesignation = RangeDesignation;
				FillString.QuantityPlanRangeBound = NextInterval_.CountPlan;
				
			EndDo;
			
			LastInterval = TempTable[NumberOfIntervals_ - 1];
			
			IntervalEndpoint = RebatesClientServer.FormatOfIntervalBoundary(LastInterval.CountPlan);
			RangeDesignation = StringFunctionsClientServer.SubstituteParametersToString(
				DesignationOfIntervalOver,
				IntervalEndpoint);
			
			FillString = ProcessedTable[LastInterval.LineNumber - 1];
			FillString.RangeDesignation = RangeDesignation;
			FillString.QuantityPlanRangeBound = 0;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  TableName - String -
//	Settings - ValueTable - table with columns:
//		* Fields - Array of String - fields for which display settings are defined
//		* Condition - DataCompositionFilter - terms of use settings
//		* Properties - Structure - property names and values 
//
Procedure SettingUpRangeDesignationField(TableName, Settings) Export
	
	FieldName = TableName + "RangeDesignation";
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	Item = Settings.Add();
	
	Item.Fields.Add(FieldName);
	
	FinancialReportingServer.NewFilter(
		Item.Condition, "More.GoodsIndicator", GoodsIndicators.Count);
	FinancialReportingServer.NewFilter(Item.Condition, "CalculationScaleType", 1); // By Ranges
	
	Item.Properties.Insert("Visible", True);
	
EndProcedure

#EndRegion

#Region GoodsByRanges

// Parameters:
//  Form - See Document.ConditionsOfCustomerRebates.Form.DocumentForm
//        - See Document.ConditionsOfVendorRebates.Form.DocumentForm
//
Procedure InitializeGoodsRanges(Form) Export
	
	If Form.ContentOfGoods <> Enums.RebatesItems.Products Then
		Return;
	EndIf;
	
	Object = Form.Object;
	Goods = Form.Object.Goods;
	
	ColumnsNames = "LineNumber, Products, Characteristic, ItemVariantsAreUsed, CountPlan, Canceled";
	GoodsTableBeingProcessed = Goods.Unload(, ColumnsNames);
	
	TempTableManager = New TempTablesManager();
	Selection = SelectionOfGoodsWithoutInitialRange(Goods, TempTableManager, True);
	While Selection.Next() Do
		
		StringOfInitialRange = Goods.Insert(Selection.LineNumber - 1);
		StringOfInitialRange.Products = Selection.Products;
		StringOfInitialRange.Characteristic = Selection.Characteristic;
		StringOfInitialRange.ItemVariantsAreUsed = Selection.ItemVariantsAreUsed;
		
	EndDo;
	
	FieldsNames = "Products, Characteristic";
	GoodsTableBeingProcessed.GroupBy(FieldsNames);
	
	UpdateGoodsRowRangesByTable(Object, GoodsTableBeingProcessed);
	
EndProcedure

// Parameters:
//  Object - See Document.ConditionsOfCustomerRebates.Form.DocumentForm.Object
//         - See Document.ConditionsOfVendorRebates.Form.DocumentForm.Object
//  GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods
//
Procedure UpdateRowRangesOfAllGoods(Object, GoodsIndicator) Export
	
	If Not RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator) Then
		Return;
	EndIf;
	
	FieldsNames = "Products, Characteristic, ItemVariantsAreUsed";
	Table_For_Processing = Object.Goods.Unload(, FieldsNames);
	Table_For_Processing.GroupBy(FieldsNames);
	UpdateGoodsRowRangesByTable(Object, Table_For_Processing);
	
EndProcedure

// Parameters:
//  Object - See Document.ConditionsOfCustomerRebates.Form.DocumentForm.Object
//         - See Document.ConditionsOfVendorRebates.Form.DocumentForm.Object
//	Products - CatalogRef.Products
//	Characteristic - CatalogRef.ItemsCharacteristics
//
Procedure UpdateGoodsRowRangesByGoods(Object, Products, Characteristic) Export
	
	Table_For_Processing = NewTableOfGoodsByProcessingRanges();
	
	RowOfGoods = Table_For_Processing.Add();
	RowOfGoods.Products = Products;
	RowOfGoods.Characteristic = Characteristic;
	
	UpdateGoodsRowRangesByTable(Object, Table_For_Processing);
	
EndProcedure

// Parameters:
//  Object - See Document.ConditionsOfCustomerRebates.Form.DocumentForm.Object
//         - See Document.ConditionsOfVendorRebates.Form.DocumentForm.Object
//	GoodsTableBeingProcessed - ValueTable:
//		* Products - CatalogRef.Products
//		* Characteristic - CatalogRef.ItemsCharacteristics
//		* ItemVariantsAreUsed - Boolean
//
Procedure UpdateGoodsRowRangesByTable(Object, GoodsTableBeingProcessed) Export
	
	Goods = Object.Goods;
	UpdateDesignationOfItemRowRange(Goods, GoodsTableBeingProcessed);
	
EndProcedure

// Parameters:
//  Goods - FormDataCollection, ValueTable - Goods
//  GoodsTableBeingProcessed - ValueTable - Goods Table Being Processed:
// * Products - CatalogRef.Products
// * Characteristic - CatalogRef.ItemsCharacteristics
// * ItemVariantsAreUsed - Boolean
// 
Procedure UpdateDesignationOfItemRowRange(Goods, GoodsTableBeingProcessed) Export
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Products", Catalogs.Products.EmptyRef());
	FilterParameters.Insert("Characteristic", Catalogs.ItemsCharacteristics.EmptyRef());
	FilterParameters.Insert("Canceled", False);
	
	UpdateRowRangeDesignation(Goods, GoodsTableBeingProcessed, FilterParameters);
	
EndProcedure

// Parameters:
//  VerificationObject - DocumentObject.ConditionsOfCustomerRebates, DocumentObject.ConditionsOfVendorRebates -
//  TablePresentation - String - Presentation of the table part being checked
//  TempTableManager - TempTablesManager - 
//  Cancel - Boolean - Cancel
//
Procedure CheckGoodsAvailabilityOfInitialRange(VerificationObject, TablePresentation, TempTableManager, Cancel) Export
	
	TableName = "Goods";
	ErrorTemplate = NStr("vi = 'Đối với %1 chưa chỉ ra khoảng ban đầu (từ số lượng 0)';
						|ru = 'Для %1 не указан начальный диапазон (от количества 0)';
						|en = 'For %1, the initial range (from 0 quantity) is not specified'; fa = 'For %1, the initial range (from 0 quantity) is not specified';
						|it = 'For %1, the initial range (from 0 quantity) is not specified';
						|pl = 'For %1, the initial range (from 0 quantity) is not specified';
						|tr = '%1 için başlangıç aralığı belirtilmemiş (0 sayısı itibarıyla)'");
	TabularSection = VerificationObject[TableName]; // FormDataCollection, DocumentTabularSection.ConditionsOfCustomerRebates.Goods, DocumentTabularSection.ConditionsOfVendorRebates.Goods
	
	Selection = SelectionOfGoodsWithoutInitialRange(TabularSection, TempTableManager);
	
	While Selection.Next() Do
		
		ProductPresentation= ProductsClientServer.ProductPresentation(
			Selection.Products,
			Selection.Characteristic);
		
		PathToField = CommonClientServer.PathToTabularSection(
			TableName, Selection.LineNumber, "CountPlan");
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			ProductPresentation);
		
		Common.MessageToUser(MessageText, VerificationObject, PathToField,, Cancel);
		
	EndDo;
	
EndProcedure

// Parameters:
//  VerificationObject - DocumentObject.ConditionsOfCustomerRebates, DocumentObject.ConditionsOfVendorRebates -
//  TablePresentation - String - Presentation of the table part being checked
//  TempTableManager - TempTablesManager -
//  Cancel - Boolean - Cancel
//
Procedure CheckGoodsIdentityOfTheseRanges(VerificationObject, TablePresentation, TempTableManager, Cancel) Export
	
	TableName = "Goods";
	ErrorTemplateBeginningOfPeriod = NStr("vi = 'Đối với %1 đã chỉ ra các kỳ khác nhau bắt đầu hiệu lực';
											|ru = 'Для %1 указаны разные периоды начало действия';
											|en = 'For %1, different validity start periods are specified'; fa = 'For %1, different validity start periods are specified';
											|it = 'For %1, different validity start periods are specified';
											|pl = 'For %1, different validity start periods are specified';
											|tr = '%1 için başlangıç eylemlerinde farklı dönemler belirtilmiş'");
	ErrorTemplateEndOfPeriod = NStr("vi = 'Đối với %1 đã chỉ ra các kỳ khác nhau kết thúc hiệu lực';
									|ru = 'Для %1 указаны разные периоды окончания действия';
									|en = 'For %1, different validity end periods are specified'; fa = 'For %1, different validity end periods are specified';
									|it = 'For %1, different validity end periods are specified';
									|pl = 'For %1, different validity end periods are specified';
									|tr = '%1 için bitiş eylemlerinde farklı dönemler belirtilmiş'");
	ErrorTemplateBasePrice = NStr("vi = 'Đối với %1 đã chỉ ra các đơn giá cơ bản khác nhau trong các dòng đang có hiệu lực';
									|ru = 'Для %1 указаны разные базовые цены в действующих строках';
									|en = 'For %1, different base prices are specified in active lines'; fa = 'For %1, different base prices are specified in active lines';
									|it = 'For %1, different base prices are specified in active lines';
									|pl = 'For %1, different base prices are specified in active lines';
									|tr = '%1 için geçerli satırlarda farklı temel fiyatlar belirtilmiş'");
	TabularSection = VerificationObject[TableName]; // TabularSection
	
	//@skip-check invocation-parameter-type-intersect
	// Composite Type
	Selection = SelectionOfGoodsRangesWithDifferentData(TabularSection, TempTableManager);
	
	While Selection.Next() Do
		
		ProductPresentation= ProductsClientServer.ProductPresentation(
			Selection.Products,
			Selection.Characteristic);
		
		If Selection.QuantityBeginningOfAction > 1 Then
			
			PathToField = CommonClientServer.PathToTabularSection(
				TableName, Selection.LineNumber, "ValidOnDate");
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTemplateBeginningOfPeriod,
				ProductPresentation);
			
			Common.MessageToUser(MessageText, VerificationObject, PathToField,, Cancel);
			
		EndIf;
		
		If Selection.NumberOfExpiration > 1 Then
			
			PathToField = CommonClientServer.PathToTabularSection(
				TableName, Selection.LineNumber, "ValidTo");
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTemplateEndOfPeriod,
				ProductPresentation);
			
			Common.MessageToUser(MessageText, VerificationObject, PathToField,, Cancel);
			
		EndIf;
		
		If Selection.QuantityBasePrice > 1 Then
			
			PathToField = CommonClientServer.PathToTabularSection(
				TableName, Selection.LineNumber, "BasePrice");
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTemplateBasePrice,
				ProductPresentation);
			
			Common.MessageToUser(MessageText, VerificationObject, PathToField,, Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  VerificationObject - DocumentObject.ConditionsOfCustomerRebates, DocumentObject.ConditionsOfVendorRebates -
//  TablePresentation - String - Presentation of the table part being checked
//  TempTableManager - TempTablesManager - 
//  Cancel - Boolean - Cancel
//
Procedure CheckGoodsForBonusInterest(VerificationObject, TablePresentation, TempTableManager, Cancel) Export
	
	TableName = "Goods";
	ErrorTemplate = NStr("vi = 'Đối với %1 chưa chỉ ra phần trăm thưởng nào trong các dòng';
						|ru = 'Для %1 не указано ни одного процента бонуса в строках';
						|en = 'For %1, no rebate percentage is specified in the lines'; fa = 'For %1, no rebate percentage is specified in the lines';
						|it = 'For %1, no rebate percentage is specified in the lines';
						|pl = 'For %1, no rebate percentage is specified in the lines';
						|tr = '%1 için satırlarda herhangi bir yüzde bonusu belirtilmemiş'");
	TabularSection = VerificationObject[TableName]; // TabularSection
	
	//@skip-check invocation-parameter-type-intersect
	// Composite Type
	Selection = SelectionOfGoodsWithoutBonusInterest(TabularSection, TempTableManager);
	
	While Selection.Next() Do
		
		ProductPresentation= ProductsClientServer.ProductPresentation(
			Selection.Products,
			Selection.Characteristic);
		
		PathToField = CommonClientServer.PathToTabularSection(
			TableName, Selection.LineNumber, "Percent");
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			ProductPresentation);
		
		Common.MessageToUser(MessageText, VerificationObject, PathToField,, Cancel);
		
	EndDo;
	
EndProcedure

// Parameters:
//  Object - See Document.ConditionsOfCustomerRebates.Form.DocumentForm.Object
//         - See Document.ConditionsOfVendorRebates.Form.DocumentForm.Object
//  IDCurrentRow - Number - Current row id
//  OnlyPeriods - Boolean - update only action periods
//
Procedure FillInUniformDataOfGoodsLineRange(Object, IDCurrentRow, OnlyPeriods = False) Export
	
	If Object.Goods.Count() < 2 Then
		Return;
	EndIf;
	
	RowOfGoods = Object.Goods.FindByID(IDCurrentRow);
	
	DataFilledIn = Not RowOfGoods.Products.IsEmpty();
	
	If DataFilledIn Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Products", RowOfGoods.Products);
		FilterParameters.Insert("Characteristic", RowOfGoods.Characteristic);
		FilterParameters.Insert("ItemVariantsAreUsed", RowOfGoods.ItemVariantsAreUsed);
		
		FoundRows = Object.Goods.FindRows(FilterParameters);
		For Each FoundRow In FoundRows Do
			
			If FoundRow.GetID() = IDCurrentRow Then
				Continue;
			EndIf;
			
			RowOfGoods.ValidOnDate = FoundRow.ValidOnDate;
			RowOfGoods.ValidTo = FoundRow.ValidTo;
			If Not OnlyPeriods Then
				RowOfGoods.BasePrice = FoundRow.BasePrice;
			EndIf;
			
		EndDo;
		
	Else
		
		RowOfGoods.ValidOnDate = Date(1, 1, 1);
		RowOfGoods.ValidTo = Date(1, 1, 1);
		If Not OnlyPeriods Then
			RowOfGoods.BasePrice = 0;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region PropertiesByRanges

// Parameters:
//  Form - See Document.ConditionsOfCustomerRebates.Form.DocumentForm
//        - See Document.ConditionsOfVendorRebates.Form.DocumentForm
//
Procedure InitializePropertyRanges(Form) Export
	
	If Form.ContentOfGoods <> Enums.RebatesItems.ProductItemProperty Then
		Return;
	EndIf;
	
	Object = Form.Object;
	ProductProperties_ = Form.Object.ProductProperties_;
	
	ColumnsNames = "LineNumber, PropertyValue, CountPlan, Canceled";
	ProcessedTable = ProductProperties_.Unload(, ColumnsNames);
	
	TempTableManager = New TempTablesManager();
	Selection = SelectingPropertiesWithoutInitialRange(ProductProperties_, TempTableManager, True);
	While Selection.Next() Do
		
		StringOfInitialRange = ProductProperties_.Insert(Selection.LineNumber - 1);
		StringOfInitialRange.PropertyValue = Selection.PropertyValue;
		
	EndDo;
	
	FieldsNames = "PropertyValue";
	ProcessedTable.GroupBy(FieldsNames);
	
	UpdateRangesOfPropertyRowsByTable(Object, ProcessedTable);
	
EndProcedure

// Parameters:
//  Object - See Document.ConditionsOfCustomerRebates.Form.DocumentForm.Object
//         - See Document.ConditionsOfVendorRebates.Form.DocumentForm.Object
//  GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods
//
Procedure UpdateRowRangesOfAllProperties(Object, GoodsIndicator) Export
	
	If Not RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator) Then
		Return;
	EndIf;
	
	FieldsNames = "PropertyValue";
	Table_For_Processing = Object.ProductProperties_.Unload(, FieldsNames);
	Table_For_Processing.GroupBy(FieldsNames);
	UpdateRangesOfPropertyRowsByTable(Object, Table_For_Processing);
	
EndProcedure

// Parameters:
//  Object - See Document.ConditionsOfCustomerRebates.Form.DocumentForm.Object
//         - See Document.ConditionsOfVendorRebates.Form.DocumentForm.Object
//	PropertyValue - DefinedType.RebateItemPropertyTypes
//
Procedure UpdatePropertyRowRangesByProperty(Object, PropertyValue) Export
	
	Table_For_Processing = NewTableOfPropertiesByRangesToBeProcessed();
	
	PropertyRow = Table_For_Processing.Add();
	PropertyRow.PropertyValue = PropertyValue;
	
	UpdateRangesOfPropertyRowsByTable(Object, Table_For_Processing);
	
EndProcedure

// Parameters:
//  Object - See Document.ConditionsOfCustomerRebates.Form.DocumentForm.Object
//         - See Document.ConditionsOfVendorRebates.Form.DocumentForm.Object
//	ProcessedTable - ValueTable:
//		* PropertyValue - DefinedType.RebateItemPropertyTypes
//
Procedure UpdateRangesOfPropertyRowsByTable(Object, ProcessedTable) Export
	
	Goods = Object.ProductProperties_;
	DenotingRangeOfPropertyLines(Goods, ProcessedTable);
	
EndProcedure

// Parameters:
//  ProductProperties_ - FormDataCollection, ValueTable - Properties
//  ProcessedTable - ValueTable - Processed property table:
// * PropertyValue - DefinedType.RebateItemPropertyTypes
// 
Procedure DenotingRangeOfPropertyLines(ProductProperties_, ProcessedTable) Export
	
	FilterParameters = New Structure;
	FilterParameters.Insert("PropertyValue", Undefined);
	FilterParameters.Insert("Canceled", False);
	
	UpdateRowRangeDesignation(ProductProperties_, ProcessedTable, FilterParameters);
	
EndProcedure

// Parameters:
//  VerificationObject - DocumentObject.ConditionsOfCustomerRebates, DocumentObject.ConditionsOfVendorRebates -
//  TablePresentation - String - Presentation of the table part being checked
//  TempTableManager - TempTablesManager - 
//  Cancel - Boolean - Cancel
//
Procedure CheckItemPropertiesForInitialRange(VerificationObject, TablePresentation, TempTableManager, Cancel) Export
	
	TableName = "ProductProperties_";
	ErrorTemplate = NStr("vi = 'Đối với %1 chưa chỉ ra khoảng ban đầu (từ số lượng 0)';
						|ru = 'Для %1 не указан начальный диапазон (от количества 0)';
						|en = 'For %1, the initial range (from 0 quantity) is not specified'; fa = 'For %1, the initial range (from 0 quantity) is not specified';
						|it = 'For %1, the initial range (from 0 quantity) is not specified';
						|pl = 'For %1, the initial range (from 0 quantity) is not specified';
						|tr = '%1 için başlangıç aralığı belirtilmemiş (0 sayısı itibarıyla)'");
	TabularSection = VerificationObject[TableName]; // FormDataCollection, DocumentTabularSection.ConditionsOfCustomerRebates.ProductProperties_, DocumentTabularSection.ConditionsOfVendorRebates.ProductProperties_
	
	Selection = SelectingPropertiesWithoutInitialRange(TabularSection, TempTableManager);
	
	While Selection.Next() Do
		
		PathToField = CommonClientServer.PathToTabularSection(
			TableName, Selection.LineNumber, "CountPlan");
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			TrimAll(Selection.PropertyValue));
		
		Common.MessageToUser(MessageText, VerificationObject, PathToField,, Cancel);
		
	EndDo;
	
EndProcedure

// Parameters:
//  VerificationObject - DocumentObject.ConditionsOfCustomerRebates, DocumentObject.ConditionsOfVendorRebates -
//  TablePresentation - String - Presentation of the table part being checked
//  TempTableManager - TempTablesManager -
//  Cancel - Boolean - Cancel
//
Procedure CheckPropertiesOfItemIdentityOfTheseRanges(VerificationObject, TablePresentation, TempTableManager, Cancel) Export
	
	TableName = "ProductProperties_";
	ErrorTemplateBeginningOfPeriod = NStr("vi = 'Đối với %1 đã chỉ ra các kỳ khác nhau bắt đầu hiệu lực';
											|ru = 'Для %1 указаны разные периоды начало действия';
											|en = 'For %1, different validity start periods are specified'; fa = 'For %1, different validity start periods are specified';
											|it = 'For %1, different validity start periods are specified';
											|pl = 'For %1, different validity start periods are specified';
											|tr = '%1 için başlangıç eylemlerinde farklı dönemler belirtilmiş'");
	ErrorTemplateEndOfPeriod = NStr("vi = 'Đối với %1 đã chỉ ra các kỳ khác nhau kết thúc hiệu lực';
									|ru = 'Для %1 указаны разные периоды окончания действия';
									|en = 'For %1, different validity end periods are specified'; fa = 'For %1, different validity end periods are specified';
									|it = 'For %1, different validity end periods are specified';
									|pl = 'For %1, different validity end periods are specified';
									|tr = '%1 için bitiş eylemlerinde farklı dönemler belirtilmiş'");
	ErrorTemplateBasePrice = NStr("vi = 'Đối với %1 đã chỉ ra các đơn giá cơ bản khác nhau trong các dòng đang có hiệu lực';
									|ru = 'Для %1 указаны разные базовые цены в действующих строках';
									|en = 'For %1, different base prices are specified in active lines'; fa = 'For %1, different base prices are specified in active lines';
									|it = 'For %1, different base prices are specified in active lines';
									|pl = 'For %1, different base prices are specified in active lines';
									|tr = '%1 için geçerli satırlarda farklı temel fiyatlar belirtilmiş'");
	TabularSection = VerificationObject[TableName]; // DocumentTabularSection.ConditionsOfCustomerRebates.ProductProperties_, DocumentTabularSection.ConditionsOfVendorRebates.ProductProperties_
	
	Selection = SelectionOfRangeItemPropertiesWithDifferentData(TabularSection, TempTableManager);
	
	While Selection.Next() Do
		
		FieldPresentation = TrimAll(Selection.PropertyValue);
		
		If Selection.QuantityBeginningOfAction > 1 Then
			
			PathToField = CommonClientServer.PathToTabularSection(
				TableName, Selection.LineNumber, "ValidOnDate");
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTemplateBeginningOfPeriod,
				FieldPresentation);
			
			Common.MessageToUser(MessageText, VerificationObject, PathToField,, Cancel);
			
		EndIf;
		
		If Selection.NumberOfExpiration > 1 Then
			
			PathToField = CommonClientServer.PathToTabularSection(
				TableName, Selection.LineNumber, "ValidTo");
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTemplateEndOfPeriod,
				FieldPresentation);
			
			Common.MessageToUser(MessageText, VerificationObject, PathToField,, Cancel);
			
		EndIf;
		
		If Selection.QuantityBasePrice > 1 Then
			
			PathToField = CommonClientServer.PathToTabularSection(
				TableName, Selection.LineNumber, "BasePrice");
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTemplateBasePrice,
				FieldPresentation);
			
			Common.MessageToUser(MessageText, VerificationObject, PathToField,, Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  VerificationObject - DocumentObject.ConditionsOfCustomerRebates, DocumentObject.ConditionsOfVendorRebates -
//  TablePresentation - String - Presentation of the table part being checked
//  TempTableManager - TempTablesManager - 
//  Cancel - Boolean - Cancel
//
Procedure CheckItemPropertiesForBonusPercentages(VerificationObject, TablePresentation, TempTableManager, Cancel) Export
	
	TableName = "Goods";
	ErrorTemplate = NStr("vi = 'Đối với %1 chưa chỉ ra phần trăm thưởng nào trong các dòng';
						|ru = 'Для %1 не указано ни одного процента бонуса в строках';
						|en = 'For %1, no rebate percentage is specified in the lines'; fa = 'For %1, no rebate percentage is specified in the lines';
						|it = 'For %1, no rebate percentage is specified in the lines';
						|pl = 'For %1, no rebate percentage is specified in the lines';
						|tr = '%1 için satırlarda herhangi bir yüzde bonusu belirtilmemiş'");
	TabularSection = VerificationObject[TableName]; // DocumentTabularSection.ConditionsOfCustomerRebates.ProductProperties_, DocumentTabularSection.ConditionsOfVendorRebates.ProductProperties_
	
	Selection = SelectionOfItemPropertiesWithoutBonusInterest(TabularSection, TempTableManager);
	
	While Selection.Next() Do
		
		PathToField = CommonClientServer.PathToTabularSection(
			TableName, Selection.LineNumber, "Percent");
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			TrimAll(Selection.PropertyValue));
		
		Common.MessageToUser(MessageText, VerificationObject, PathToField,, Cancel);
		
	EndDo;
	
EndProcedure

// Parameters:
//  Object - See Document.ConditionsOfCustomerRebates.Form.DocumentForm.Object
//         - See Document.ConditionsOfVendorRebates.Form.DocumentForm.Object
//  IDCurrentRow - Number - Current row id
//  OnlyPeriods - Boolean -
//
Procedure FillInUnifiedDataOfPropertyRowRange(Object, IDCurrentRow, OnlyPeriods = False) Export
	
	If Object.ProductProperties_.Count() < 2 Then
		Return;
	EndIf;
	
	PropertyRow = Object.ProductProperties_.FindByID(IDCurrentRow);
	
	DataFilledIn = ValueIsFilled(PropertyRow.PropertyValue);
	
	If DataFilledIn Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("PropertyValue", PropertyRow.PropertyValue);
		
		FoundRows = Object.ProductProperties_.FindRows(FilterParameters);
		For Each FoundRow In FoundRows Do
			
			If FoundRow.GetID() = IDCurrentRow Then
				Continue;
			EndIf;
			
			PropertyRow.ValidOnDate = FoundRow.ValidOnDate;
			PropertyRow.ValidTo = FoundRow.ValidTo;
			If Not OnlyPeriods Then
				PropertyRow.BasePrice = FoundRow.BasePrice;
			EndIf;
			
		EndDo;
		
	Else
		
		PropertyRow.ValidOnDate = Date(1, 1, 1);
		PropertyRow.ValidTo = Date(1, 1, 1);
		If Not OnlyPeriods Then
			PropertyRow.BasePrice = 0;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region CheckingStringPeriods

// Check changes in table periods.
// 
// Parameters:
//  ValidOnDate - Date
//  ValidTo - Date
//  MaxDate - Date
//  TableName - String
//  TablePresentation - String
//  TableRow - DocumentTabularSectionRow.ConditionsOfVendorRebates.CustomerCounterparties, DocumentTabularSectionRow.ConditionsOfVendorRebates.ClientsCounterpartiesTIN, DocumentTabularSectionRow.ConditionsOfVendorRebates.Goods, DocumentTabularSection.ConditionsOfVendorRebates.ProductProperties_, DocumentTabularSectionRow.ConditionsOfVendorRebates.Vendors, DocumentTabularSectionRow.ConditionsOfCustomerRebates.Counterparties, DocumentTabularSectionRow.ConditionsOfCustomerRebates.CounterpartiesTIN, DocumentTabularSectionRow.ConditionsOfCustomerRebates.Goods, DocumentTabularSectionRow.ConditionsOfCustomerRebates.ContractsTermsOfSales, DocumentTabularSection.ConditionsOfCustomerRebates.ProductProperties_ - The Cur row of the table
//  Cancel - Boolean
//
Procedure CheckChangesInTablePeriods(Val ValidOnDate, Val ValidTo, Val MaxDate, Val TableName, Val TablePresentation, TableRow, Cancel) Export
	
	DateEmpty = Date(1, 1, 1);
	
	If TableRow.ValidOnDate = DateEmpty Then
		CurrentStartDate = ValidOnDate;
	Else
		CurrentStartDate = TableRow.ValidOnDate;
	EndIf;
	
	If TableRow.ValidTo = DateEmpty Then
		CurrentEndDate = ValidTo;
	Else
		CurrentEndDate = TableRow.ValidTo;
	EndIf;
	
	CheckValidityOfBeginningOfLinePeriod(
		MaxDate,
		TableName,
		TablePresentation,
		CurrentStartDate,
		TableRow,
		Cancel);
	
	CheckChangeBeginningOfPeriodOfOriginalString(
		MaxDate,
		TableName,
		TablePresentation,
		CurrentStartDate,
		TableRow,
		Cancel);
	
	CheckValidityOfBeginningOfPeriodOfSourceString(
		MaxDate,
		TableName,
		TablePresentation,
		CurrentStartDate,
		TableRow,
		Cancel);
	
	CheckWhetherEndOfStringPeriodIsValid(
		MaxDate,
		TableName,
		TablePresentation,
		CurrentEndDate,
		TableRow,
		Cancel);
	
	CheckWhetherEndOfPeriodOfSourceStringHasChanged(
		MaxDate,
		TableName,
		TablePresentation,
		CurrentEndDate,
		TableRow,
		Cancel);
	
	CheckValidityOfChangingEndOfPeriodOfOriginalLine(
		MaxDate,
		TableName,
		TablePresentation,
		CurrentEndDate,
		TableRow,
		Cancel);
	
EndProcedure

// Checking for changes in tables that are not allowed to be changed without a period of validity
// 
// Parameters:
//  Object - DocumentObject.ConditionsOfCustomerRebates, DocumentObject.ConditionsOfVendorRebates -
//  ListComposition - EnumRef.RebatesLists
//  TableName - String
//  TablePresentation - String - Presentation of the table part being checked
//  Cancel - Boolean
//
Procedure CheckChangesToConditionsInTableWithoutValidityPeriods(Object, ListComposition, TableName, TablePresentation, Cancel) Export
	
	If ListComposition = Enums.RebatesLists.All Then
		Return;
	EndIf;
	
	Template = NStr("vi = 'Tại dòng %1 danh sách ""%2"" đã cấm thay đổi, bởi vì đã nhập các tính toán vào kỳ hiệu lực điều kiện';
					|ru = 'В строке %1 списка ""%2"" запрещены изменения, так как в период действия условия были введены начисления';
					|en = 'Changes are disabled in line %1 of the ""%2"" list as accruals were entered during the condition validity period'; fa = 'Changes are disabled in line %1 of the ""%2"" list as accruals were entered during the condition validity period';
					|it = 'В строке %1 списка ""%2"" запрещены изменения, так как в период действия условия были введены начисления';
					|pl = 'Changes are disabled in line %1 of the ""%2"" list as accruals were entered during the condition validity period';
					|tr = '""%2"" listesinin %1  satırında, tahakkukların şartlar döneminde geçerli olduğu dönemde devreye girdiği için değişikliklerin yapılması yasaklandı'");
	
	DataTable = Object[TableName]; // DocumentTabularSection.ConditionsOfCustomerRebates.Counterparties, DocumentTabularSection.ConditionsOfCustomerRebates.CounterpartiesTIN, DocumentTabularSection.ConditionsOfCustomerRebates.Goods, DocumentTabularSection.ConditionsOfCustomerRebates.ProductProperties_, DocumentTabularSection.ConditionsOfVendorRebates.CustomerCounterparties, DocumentTabularSection.ConditionsOfVendorRebates.ClientsCounterpartiesTIN, DocumentTabularSection.ConditionsOfVendorRebates.Goods, DocumentTabularSection.ConditionsOfVendorRebates.ProductProperties_, DocumentTabularSection.ConditionsOfVendorRebates.Vendors
	
	For Each DataString1 In DataTable Do
		
		ThereWereAdjustments = False;
			
		If Not DataString1.InitialString
		 Or DataString1.Canceled Then
			
			ThereWereAdjustments = True;
			
		EndIf;
		
		If ThereWereAdjustments Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				Template,
				String(DataString1.LineNumber),
				TablePresentation);
			Field = CommonClientServer.PathToTabularSection(
				TableName, DataString1.LineNumber, "LineNumber");
			Common.MessageToUser(MessageText,, Field, "Object", Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns:
//  Structure - New Parameters For Checking Conditions In The Table:
// * Object - Undefined, DocumentObject.ConditionsOfCustomerRebates, DocumentObject.ConditionsOfVendorRebates -
// * TableName - String - 
// * TablePresentation - String - 
// * ValidOnDate - Date - 
// * ValidTo - Date - 
// * MaxDate - Date - 
// * CheckPlanAmount - Boolean - 
// * AmountPlan - Number - used when checking the sum of the plan
// * ListComposition - EnumRef.RebatesLists - 
// * CheckPeriodsInTables - Boolean -
// 
Function NewParametersForCheckingConditionsInTable() Export
	
	DateEmpty = Date(1, 1, 1);
	
	Result = New Structure;
	
	Result.Insert("Object", Undefined);
	Result.Insert("TableName", "");
	Result.Insert("TablePresentation", "");
	Result.Insert("ValidOnDate", DateEmpty);
	Result.Insert("ValidTo", DateEmpty);
	Result.Insert("MaxDate", DateEmpty);
	Result.Insert("CheckPlanAmount", False);
	Result.Insert("AmountPlan", 0);
	Result.Insert("ListComposition", Enums.RebatesLists.EmptyRef());
	Result.Insert("CheckPeriodsInTables", False);
	
	Return Result;
	
EndFunction

// Checking the correctness of the changes made in relation to the accrual period
// 
// Parameters:
//  CheckParameters - See NewParametersForCheckingConditionsInTable
//  Cancel - Boolean
//
Procedure CheckChangesToConditionsInTable(CheckParameters, Cancel)Export
	
	TableName = CheckParameters.TableName;
	TablePresentation = CheckParameters.TablePresentation;
	ValidOnDate = CheckParameters.ValidOnDate;
	ValidTo = CheckParameters.ValidTo;
	ListComposition = CheckParameters.ListComposition;
	
	If ListComposition = Enums.RebatesLists.All
	 Or ListComposition = Enums.RebatesLists.EmptyRef()
	 Or (Not CheckParameters.CheckPeriodsInTables
	      And ListComposition = Enums.RebatesLists.Selected_) Then
		Return;
	EndIf;
	
	DateEmpty = Date(1, 1, 1);
	
	ObjectTabularSection = CheckParameters.Object[TableName]; // DocumentTabularSection.ConditionsOfCustomerRebates.Counterparties, DocumentTabularSection.ConditionsOfCustomerRebates.CounterpartiesTIN, DocumentTabularSection.ConditionsOfCustomerRebates.Goods, DocumentTabularSection.ConditionsOfCustomerRebates.ProductProperties_, DocumentTabularSection.ConditionsOfVendorRebates.CustomerCounterparties, DocumentTabularSection.ConditionsOfVendorRebates.ClientsCounterpartiesTIN, DocumentTabularSection.ConditionsOfVendorRebates.Goods, DocumentTabularSection.ConditionsOfVendorRebates.ProductProperties_, DocumentTabularSection.ConditionsOfVendorRebates.Vendors 
	For Each CurrentTableRow In ObjectTabularSection Do
		
		If ListComposition = Enums.RebatesLists.Selected_ Then
			
			CheckChangesInTablePeriods(
				ValidOnDate,
				ValidTo,
				CheckParameters.MaxDate,
				TableName,
				TablePresentation,
				CurrentTableRow,
				Cancel);
			
			If CurrentTableRow.Canceled
			   And CurrentTableRow.StartDateBeforeChange <= CheckParameters.MaxDate Then
				
				Template = NStr("vi = 'Tại dòng %1 danh sách ""%2"" không thể bị hủy bỏ. Trong kỳ hiệu lực các điều kiện đã được ghi nhận vào tính toán';
								|ru = 'В строке %1 списка ""%2"" отмена невозможна. В период действия условия были зарегистрированы начисления';
								|en = 'Cannot cancel in line %1 of the ""%2"" list. Accruals were registered during the condition validity period'; fa = 'Cannot cancel in line %1 of the ""%2"" list. Accruals were registered during the condition validity period';
								|it = 'В строке %1 списка ""%2"" отмена невозможна. В период действия условия были зарегистрированы начисления';
								|pl = 'Cannot cancel in line %1 of the ""%2"" list. Accruals were registered during the condition validity period';
								|tr = '""%2"" listesinin %1 satırının iptal edilmesi mümkün değildir. Şartların geçerlilik döneminin tahakkukları kaydedildi'");
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					Template,
					String(CurrentTableRow.LineNumber),
					TablePresentation);
				
				Field = CommonClientServer.PathToTabularSection(
					TableName, CurrentTableRow.LineNumber, "LineNumber");
					
				Common.MessageToUser(MessageText,, Field, "Object", Cancel);
				
			EndIf;
			
			If CheckParameters.CheckPlanAmount Then
				
				If CurrentTableRow.SumPlan = 0 Then
					PlanAmountIsCurrent = CheckParameters.AmountPlan;
				Else
					PlanAmountIsCurrent = CurrentTableRow.SumPlan;
				EndIf;
				
				If CurrentTableRow.InitialString
				   And PlanAmountIsCurrent <> CurrentTableRow.AmountPlanBeforeChange
				   And CurrentTableRow.StartDateBeforeChange <= CheckParameters.MaxDate Then
					
					Template = NStr("vi = 'Tại dòng %1 danh sách ""%2"" cấm thay đổi số tiền dự tính. Trong kỳ hiệu lực điều kiện đã được ghi nhận vào tính toán';
									|ru = 'В строке %1 списка ""%2"" сумму плана менять запрещено. В период действия условия были зарегистрированы начисления';
									|en = 'Cannot change the plan amount in line %1 of the ""%2"" list. Accruals were registered during the condition validity period'; fa = 'Cannot change the plan amount in line %1 of the ""%2"" list. Accruals were registered during the condition validity period';
									|it = 'В строке %1 списка ""%2"" сумму плана менять запрещено. В период действия условия были зарегистрированы начисления';
									|pl = 'Cannot change the plan amount in line %1 of the ""%2"" list. Accruals were registered during the condition validity period';
									|tr = '""%2"" listesinin %1 satırında plan tutarının iptal edilmesi mümkün değildir. Şartların geçerlilik döneminin tahakkukları kaydedildi'");
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
						Template,
						String(CurrentTableRow.LineNumber),
						TablePresentation);
					
					Field = CommonClientServer.PathToTabularSection(
						TableName, CurrentTableRow.LineNumber, "SumPlan");
						
					Common.MessageToUser(MessageText,, Field, "Object", Cancel);
					
				EndIf;
				
			EndIf;
			
		Else
			
			ThereWereAdjustments = False;
			
			If Not CurrentTableRow.InitialString
			 Or CurrentTableRow.Canceled
			 Or CurrentTableRow.ValidTo <> DateEmpty
			 Or CurrentTableRow.ValidOnDate <> DateEmpty Then
				
				ThereWereAdjustments = True;
				
			EndIf;
			
			If CheckParameters.CheckPlanAmount
			   And CurrentTableRow.SumPlan <> 0
			   And CurrentTableRow.SumPlan <> CurrentTableRow.AmountPlanBeforeChange Then
				
				ThereWereAdjustments = True;
				
			EndIf;
			
			If ThereWereAdjustments Then
				
				Template = NStr("vi = 'Tại dòng %1 danh sách ""%2"" đã cấm thay đổi, bởi vì đã nhập các tính toán vào kỳ hiệu lực điều kiện';
								|ru = 'В строке %1 списка ""%2"" запрещены изменения, так как в период действия условия были введены начисления';
								|en = 'Changes are disabled in line %1 of the ""%2"" list as accruals were entered during the condition validity period'; fa = 'Changes are disabled in line %1 of the ""%2"" list as accruals were entered during the condition validity period';
								|it = 'В строке %1 списка ""%2"" запрещены изменения, так как в период действия условия были введены начисления';
								|pl = 'Changes are disabled in line %1 of the ""%2"" list as accruals were entered during the condition validity period';
								|tr = '""%2"" listesinin %1  satırında, tahakkukların şartlar döneminde geçerli olduğu dönemde devreye girdiği için değişikliklerin yapılması yasaklandı'");
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					Template,
					String(CurrentTableRow.LineNumber),
					TablePresentation);
				Field = CommonClientServer.PathToTabularSection(
					TableName, CurrentTableRow.LineNumber, "LineNumber");
				Common.MessageToUser(MessageText,, Field, "Object", Cancel);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Posting

Procedure ClearUpToDateDataRegisters(DocumentRef, RegisterNames)
	
	For Each RegisterName In RegisterNames Do
		
		RecordSet = InformationRegisters[RegisterName].CreateRecordSet();
		RecordSet.Filter.TermDocument.Set(DocumentRef);
		RecordSet.Read();
		RecordSet.Clear();
		RecordSet.Write();
		
	EndDo;
	
EndProcedure

Procedure CreateRegistersOfUpToDateData(DocumentRecorder, DocumentBasis, RegisterNames)
	
	StringOfRegisters = StrConcat(RegisterNames, ",");
	
	TablesForRegisteredRecords = DocumentsPosting.DocumentDataForPosting(DocumentRecorder, StringOfRegisters);
	For Each RegisterName In RegisterNames Do
		
		TableName = "Table" + RegisterName;
		
		RecordSet = InformationRegisters[RegisterName].CreateRecordSet();
		RecordSet.Filter.TermDocument.Set(DocumentBasis);
		RecordSet.Read();
		RecordSet.Clear();
		
		// We can not prepare the table if it is not used according to the settings, but it is required to clear the records
		If TablesForRegisteredRecords.Property(TableName) Then
			
			DataTable = TablesForRegisteredRecords[TableName]; // ValueTable
			RecordSet.Load(DataTable);
			
		EndIf;
		
		RecordSet.Write();
		
	EndDo;
	
EndProcedure

// See InitializeChangeControlData
Procedure InitializationOfChangeControlCustomerRebates(Query, QueryTexts, Document) Export
	
	ThereAreChangesOfRegisteredRecordsToDesign = DocumentsPosting.ThereAreRecordsInTable(
		Document, "RetroCustomerBonusesAreRegisteredRecordedUpdate");
	
	If Not ThereAreChangesOfRegisteredRecordsToDesign Then
		Return;
	EndIf;
	
	Query.SetParameter("DateOfControlAfter", New Boundary(EndOfDay(Document.Date), BoundaryType.Including));
	
	QueryText =
	"SELECT
	|	TRUE AS ControlAsOfDocumentDate,
	|	CustomerRebatesBalance.Organization AS Organization,
	|	CustomerRebatesBalance.Counterparty AS Counterparty,
	|	CustomerRebatesBalance.Partner AS Partner,
	|	CustomerRebatesBalance.BeginOfPeriod AS BeginOfPeriod,
	|	CustomerRebatesBalance.PeriodEnding AS PeriodEnding,
	|	CustomerRebatesBalance.TermDocument AS TermDocument,
	|	CustomerRebatesBalance.Currency AS Currency,
	|	CustomerRebatesBalance.AmountBonusBalance - CustomerRebatesBalance.ToCertifyBalance - CustomerRebatesBalance.ToSignBalance - CustomerRebatesBalance.ToWriteOffBalance AS AmountBonusBalance
	|FROM
	|	AccumulationRegister.CustomerRebates.Balance(&DateOfControlAfter, (Organization, Counterparty, Partner, BeginOfPeriod,	PeriodEnding, TermDocument, Currency) IN
	|		(SELECT
	|			Table.Organization,
	|			Table.Counterparty,
	|			Table.Partner,
	|			Table.BeginOfPeriod,
	|			Table.PeriodEnding,
	|			Table.TermDocument,
	|			Table.Currency
	|		FROM
	|			RetroCustomerBonusesAreRegisteredRecordedUpdate AS Table)) AS CustomerRebatesBalance
	|WHERE
	|	CustomerRebatesBalance.AmountBonusBalance - CustomerRebatesBalance.ToCertifyBalance - CustomerRebatesBalance.ToSignBalance - CustomerRebatesBalance.ToWriteOffBalance < 0
	|
	|UNION
	|
	|SELECT
	|	FALSE AS ControlAsOfDocumentDate,
	|	CustomerRebatesBalance.Organization AS Organization,
	|	CustomerRebatesBalance.Counterparty AS Counterparty,
	|	CustomerRebatesBalance.Partner AS Partner,
	|	CustomerRebatesBalance.BeginOfPeriod AS BeginOfPeriod,
	|	CustomerRebatesBalance.PeriodEnding AS PeriodEnding,
	|	CustomerRebatesBalance.TermDocument AS TermDocument,
	|	CustomerRebatesBalance.Currency AS Currency,
	|	CustomerRebatesBalance.AmountBonusBalance - CustomerRebatesBalance.ToCertifyBalance - CustomerRebatesBalance.ToSignBalance - CustomerRebatesBalance.ToWriteOffBalance AS AmountBonusBalance
	|FROM
	|	AccumulationRegister.CustomerRebates.Balance(, (Organization, Counterparty, Partner, BeginOfPeriod, PeriodEnding,	TermDocument, Currency) IN
	|		(SELECT
	|			Table.Organization,
	|			Table.Counterparty,
	|			Table.Partner,
	|			Table.BeginOfPeriod,
	|			Table.PeriodEnding,
	|			Table.TermDocument,
	|			Table.Currency
	|		FROM
	|			RetroCustomerBonusesAreRegisteredRecordedUpdate AS Table)) AS CustomerRebatesBalance
	|WHERE
	|	CustomerRebatesBalance.AmountBonusBalance - CustomerRebatesBalance.ToCertifyBalance - CustomerRebatesBalance.ToSignBalance - CustomerRebatesBalance.ToWriteOffBalance < 0";
	
	QueryTexts.Add(QueryText, "ErrorsInDebitingBonusAmounts");
	
EndProcedure

// See ReportChangeControlResults
Procedure ChangeControlCustomerRebates(ControlResults, Document, Cancel)
	
	If Not DocumentsPosting.ThereAreRecordsInTable(Document, "RetroCustomerBonusesAreRegisteredRecordedUpdate") Then
		Return;
	EndIf;
	
	MessageTemplateForDocumentDate = NStr("vi = 'Không đủ số tiền thưởng trong kỳ từ %1 đến %2 theo chứng từ ""%3"", đối tác ""%4"" và bạn hàng ""%5"" vào ngày chứng từ.
										  |Vượt quá: %6 %7';
										  |ru = 'Недостаточно суммы бонуса за период с %1 по %2 по документу ""%3"", контрагенту ""%4"" и партнеру ""%5"" на дату документа.
										  |Превышение: %6 %7';
										  |en = 'The rebate amount is insufficient for the period from %1 to %2 for the ""%3"" document, the ""%4"" counterparty, and the ""%5"" partner as of the document date.
										  |Exceeded: %6%7'; fa = 'The rebate amount is insufficient for the period from %1 to %2 for the ""%3"" document, the ""%4"" counterparty, and the ""%5"" partner as of the document date.
										  |Exceeded: %6%7';
										  |it = 'Недостаточно суммы бонуса за период с %1 по %2 по документу ""%3"", контрагенту ""%4"" и партнеру ""%5"" на дату документа.
										  |Превышение: %6 %7';
										  |pl = 'The rebate amount is insufficient for the period from %1 to %2 for the ""%3"" document, the ""%4"" counterparty, and the ""%5"" partner as of the document date.
										  |Exceeded: %6%7';
										  |tr = 'Belge tarihi itibariyle belge “%3”, karşı taraf “%4” ve ortak “%5” için %1 ila %2 dönemi için yetersiz ikramiye tutarı. 
										  |Aşkın: %6 %7'");
	
	GeneralMessageTemplate = NStr("vi = 'Không đủ số tiền thưởng trong kỳ từ %1 đến %2 theo chứng từ ""%3"", đối tác ""%4"" và bạn hàng ""%5"".
								|Vượt quá: %6 %7';
								|ru = 'Недостаточно суммы бонуса за период с %1 по %2 по документу ""%3"", контрагенту ""%4"" и партнеру ""%5"".
								|Превышение: %6 %7';
								|en = 'The rebate amount is insufficient for the period from %1 to %2 for the ""%3"" document, the ""%4"" counterparty, and the ""%5"" partner.
								|Exceeded: %6%7'; fa = 'The rebate amount is insufficient for the period from %1 to %2 for the ""%3"" document, the ""%4"" counterparty, and the ""%5"" partner.
								|Exceeded: %6%7';
								|it = 'Недостаточно суммы бонуса за период с %1 по %2 по документу ""%3"", контрагенту ""%4"" и партнеру ""%5"".
								|Превышение: %6 %7';
								|pl = 'The rebate amount is insufficient for the period from %1 to %2 for the ""%3"" document, the ""%4"" counterparty, and the ""%5"" partner.
								|Exceeded: %6%7';
								|tr = 'Belge “%3”, karşı taraf “%4” ve ortak “%5” için %1''den %2''ye kadar olan dönem için yetersiz ikramiye miktarı. 
								|Aşkın: %6 %7'");
	
	For Each ErrorString In ControlResults.ErrorsInDebitingBonusAmounts Do
		
		ControlAsOfDocumentDate = ErrorString.ControlAsOfDocumentDate;
		ExcessAmount = Format(- ErrorString.AmountBonusBalance, "NFD=2;");
		BeginOfPeriod = Format(ErrorString.BeginOfPeriod, "DLF=D;");
		PeriodEnding = Format(ErrorString.PeriodEnding, "DLF=D;");
		TermDocument = String(ErrorString.TermDocument);
		Currency = String(ErrorString.Currency);
		Partner = String(ErrorString.Partner);
		Counterparty = String(ErrorString.Counterparty);
		
		Template = GeneralMessageTemplate;
		If ControlAsOfDocumentDate Then
			
			Template = MessageTemplateForDocumentDate;
			
		EndIf;
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			Template,
			BeginOfPeriod,
			PeriodEnding,
			TermDocument,
			Counterparty,
			Partner,
			ExcessAmount,
			Currency);
		
		Common.MessageToUser(MessageText, Document,,, Cancel);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region AccessManagement

// Parameters:
//  ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription
//
Procedure ToSupplementProfileWithReadingRolesRebateKindOfClients(ProfileDetails)
	
	ProfileDetails.Roles.Add("SubsystemCRMAndMarketing");
	ProfileDetails.Roles.Add("SectionCRMAndMarketingCustomerRebates");
	
	ProfileDetails.Roles.Add("ReadCustomerRebatesKinds");
	
EndProcedure

Procedure AddResponsibleProfileRebateKindOfCustomers(ProfilesDetails, ParametersOfUpdate)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name = "ResponsibleForRebatingKindsOfCustomersRetroBonuses";
	ProfileDetails.Id = "01f05bc6-7524-42db-b87f-c303d0ac3349";
	ProfileDetails.Parent = "MasterDataAndSettings";
	ProfileDetails.Description =
		NStr("vi = 'Người chịu trách nhiệm về thông số thưởng lũy kế cho khách hàng (bổ sung)';
			|ru = 'Ответственный за параметры ретро-бонусов клиентов (дополнительный)';
			|en = 'Person responsible for customer rebate parameters (additional)'; fa = 'Person responsible for customer rebate parameters (additional)';
			|it = 'Ответственный за параметры ретро-бонусов клиентов (дополнительный)';
			|pl = 'Person responsible for customer rebate parameters (additional)';
			|tr = 'Müşterilerin retro-bonuslarının parametrelerinden sorumludur (ek)'",
			 Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("vi = 'Hồ sơ cấp quyền thay đổi dạng thưởng lũy kế cho khách hàng.
			 |Cần ấn định bổ sung đến hồ sơ khác bất kỳ có quyền đăng nhập vào hệ thống.';
			 |ru = 'Профиль предоставляет права на изменение видов ретро-бонусов клиентов.
			 |Должен быть назначен в дополнение к любому другому профилю с правом входа в систему.';
			 |en = 'The profile grants the right to change customer rebate kinds.
			 |It must be assigned in addition to any other profile with authorization rights.'; fa = 'The profile grants the right to change customer rebate kinds.
			 |It must be assigned in addition to any other profile with authorization rights.';
			 |it = 'Профиль предоставляет права на изменение видов ретро-бонусов клиентов.
			 |Должен быть назначен в дополнение к любому другому профилю с правом входа в систему.';
			 |pl = 'The profile grants the right to change customer rebate kinds.
			 |It must be assigned in addition to any other profile with authorization rights.';
			 |tr = 'Profil, müşterilerin retro bonus türlerini değiştirme hakkı verir.
			 |Giriş haklarına sahip diğer profillere ek olarak atanmalıdır.'",
			 Common.DefaultLanguageCode());
	
	ToSupplementProfileWithReadingRolesRebateKindOfClients(ProfileDetails);
	
	ProfileDetails.Roles.Add("AddEditCustomerRebatesKinds");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddProfileManagerOfCustomerRebates(ProfilesDetails, ParametersOfUpdate)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name = "ManagerOfCustomerRebates";
	ProfileDetails.Id = "44ec2720-e674-40fa-aec7-04fd4f3f6c6f";
	ProfileDetails.Parent = "Sales";
	ProfileDetails.Description =
		NStr("vi = 'Người quản lý thưởng lũy kế cho khách hàng (bổ sung)';
			|ru = 'Менеджер ретро-бонусов клиентов (дополнительный)';
			|en = 'Manager of customer rebates (additional)'; fa = 'Manager of customer rebates (additional)';
			|it = 'Менеджер ретро-бонусов клиентов (дополнительный)';
			|pl = 'Manager of customer rebates (additional)';
			|tr = 'Müşterilerin retro-bonuslarının yöneticisi (ek)'",
			 Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("vi = 'Hồ sơ cấp quyền ghi nhận điều kiện, tính toán, ghi giảm thưởng lũy kế cho khách hàng.
			 |Cần ấn định bổ sung vào hồ sơ người quản lý bán hàng hoặc người quản lý bộ phận bán hàng.';
			 |ru = 'Профиль предоставляет права ведения условий, начислений, списаний ретро-бонусов клиентов.
			 |Должен быть назначен в дополнение к профилю менеджера продаж или руководителя отдела продаж.';
			 |en = 'The profile grants the right to maintain conditions, accruals, and write-offs of customer rebates.
			 |It must be assigned in addition to the sales representative profile or the sales manager profile.'; fa = 'The profile grants the right to maintain conditions, accruals, and write-offs of customer rebates.
			 |It must be assigned in addition to the sales representative profile or the sales manager profile.';
			 |it = 'Профиль предоставляет права ведения условий, начислений, списаний ретро-бонусов клиентов.
			 |Должен быть назначен в дополнение к профилю менеджера продаж или руководителя отдела продаж.';
			 |pl = 'The profile grants the right to maintain conditions, accruals, and write-offs of customer rebates.
			 |It must be assigned in addition to the sales representative profile or the sales manager profile.';
			 |tr = 'Profil, müşterilerin retro bonuslarının koşullarını, tahakkuklarını, borçlarını sürdürme hakları verir.
			 |Satış müdürü veya satış müdürü profiline ek olarak atanmalıdır.'",
			 Common.DefaultLanguageCode());
	
	ToSupplementProfileWithReadingRolesRebateKindOfClients(ProfileDetails);
	
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadMasterData");
	
	ProfileDetails.Roles.Add("AddEditConditionsOfCustomerRebates");
	ProfileDetails.Roles.Add("AddEditAccrualsOfCustomerRebates");
	ProfileDetails.Roles.Add("UseDataProcessorBulkAccrualOfCustomerRebates");
	ProfileDetails.Roles.Add("AddEditWriteOffCustomerRebates");
	
	ProfileDetails.Roles.Add("ViewReportCustomerRebatesStatement");
	ProfileDetails.Roles.Add("ViewReportCalculateCustomerRebates");
	
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddParticipantProfileToAgreeOnTermsOfCustomerRebates(ProfilesDetails, ParametersOfUpdate)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name = "ParticipantInAgreementOfTermsOfCustomerRebates";
	ProfileDetails.Id = "a9d6dc14-4886-4d20-b30a-f8ae3c2956c4";
	ProfileDetails.Parent = "Sales";
	ProfileDetails.Description =
		NStr("vi = 'Người tham gia thống nhất điều kiện thưởng lũy kế cho khách hàng (bổ sung)';
			|ru = 'Участник согласования условий ретро-бонусов клиентов (дополнительный)';
			|en = 'Employee approving conditions of customer rebates (additional)'; fa = 'Employee approving conditions of customer rebates (additional)';
			|it = 'Участник согласования условий ретро-бонусов клиентов (дополнительный)';
			|pl = 'Employee approving conditions of customer rebates (additional)';
			|tr = 'Müşteriler için retro bonus şartlarının kabul edilmesinde katılımcı (ek)'",
			 Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("vi = 'Hồ sơ cấp quyền thống nhất trực tiếp cho chứng từ điều kiện thưởng lũy kế.
			 |Cần ấn định bổ sung vào hồ sơ ""Người quản lý thưởng lũy kế cho khách hàng (bổ sung)""';
			 |ru = 'Профиль предоставляет право непосредственного согласования документ условий ретро-бонусов клиентов.
			 |Должен быть назначен в дополнение к профилю ""Менеджер ретро-бонусов клиентов (дополнительный)""';
			 |en = 'The profile grants the right to approve the customer rebate conditions document.
			 |It must be assigned in addition to the ""Manager of customer rebates (additional)"" profile'; fa = 'The profile grants the right to approve the customer rebate conditions document.
			 |It must be assigned in addition to the ""Manager of customer rebates (additional)"" profile';
			 |it = 'Профиль предоставляет право непосредственного согласования документ условий ретро-бонусов клиентов.
			 |Должен быть назначен в дополнение к профилю ""Менеджер ретро-бонусов клиентов (дополнительный)""';
			 |pl = 'The profile grants the right to approve the customer rebate conditions document.
			 |It must be assigned in addition to the ""Manager of customer rebates (additional)"" profile';
			 |tr = 'Profil, retro bonus hüküm ve koşulları belgesini doğrudan anlaşma yetkisini tanılamaktadır.
			 | ""Müşteri Retro Bonus Yöneticisi (ek)"" profiline ek olarak atanmalıdır'",
			 Common.DefaultLanguageCode());
	
	ProfileDetails.Roles.Add("RightToApproveConditionsOfCustomerRebates");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddProfileResponsibleForCustomerBonusCertificatesAdditional(ProfilesDetails, ParametersOfUpdate)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name = "ResponsibleActsOfPremiumsToCustomersAdditional";
	ProfileDetails.Id = "852ffecd-ef3c-4be8-ab91-05c17c2645ba";
	ProfileDetails.Parent = "Sales";
	ProfileDetails.Description =
		NStr("vi = 'Người chịu trách nhiệm thông báo thưởng cho khách hàng (bổ sung)';
			|ru = 'Ответственный за акты премий клиентам (дополнительный)';
			|en = 'Person responsible for customer bonus certificates (additional)'; fa = 'Person responsible for customer bonus certificates (additional)';
			|it = 'Ответственный за акты премий клиентам (дополнительный)';
			|pl = 'Person responsible for customer bonus certificates (additional)';
			|tr = 'Müşterilere yönelik ikramiye eylemlerinden sorumludur (ek)'",
			 Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("vi = 'Hồ sơ cấp quyền tạo thông báo thưởng cho khách hàng.
			 |Cần ấn định bổ sung vào hồ sơ ""Người quản lý thưởng lũy kế cho khách hàng (bổ sung)""';
			 |ru = 'Профиль предоставляет право оформления актов премий клиентам.
			 |Должен быть назначен в дополнение к профилю ""Менеджер ретро-бонусов клиентов (дополнительный)""';
			 |en = 'The profile grants the right to issue customer bonus certificates.
			 |It must be assigned in addition to the ""Manager of customer rebates (additional)"" profile'; fa = 'The profile grants the right to issue customer bonus certificates.
			 |It must be assigned in addition to the ""Manager of customer rebates (additional)"" profile';
			 |it = 'Профиль предоставляет право оформления актов премий клиентам.
			 |Должен быть назначен в дополнение к профилю ""Менеджер ретро-бонусов клиентов (дополнительный)""';
			 |pl = 'The profile grants the right to issue customer bonus certificates.
			 |It must be assigned in addition to the ""Manager of customer rebates (additional)"" profile';
			 |tr = 'Bu profil, müşteri bonus sertifikaları düzenleme hakkı verir.
			 | “Müşteri Retro Bonus Yöneticisi (ek)” profiline ek olarak atanmalıdır'",
			 Common.DefaultLanguageCode());
	
	ProfileDetails.Roles.Add("AddEditCustomerBonusCertificate");
	
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

// Parameters:
//  ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription
//
Procedure SupplementProfileWithReadingRolesOfRebateKindOfSuppliers(ProfileDetails)
	
	ProfileDetails.Roles.Add("PurchaseSubsystem");
	ProfileDetails.Roles.Add("PurchasingVendorRebates");
	
	ProfileDetails.Roles.Add("ReadVendorRebateTypes");
	
EndProcedure

Procedure AddResponsibleProfileRebateKindOfSuppliers(ProfilesDetails, ParametersOfUpdate)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name = "ResponsibleTypesOfVendorRebates";
	ProfileDetails.Id = "830073fa-d91f-4abd-a4cf-16bcd4edf8fc";
	ProfileDetails.Parent = "MasterDataAndSettings";
	ProfileDetails.Description =
		NStr("vi = 'Người chịu trách nhiệm về tham số thưởng lũy kế cho khách hàng (bổ sung)';
			|ru = 'Ответственный за параметры ретро-бонусов поставщиков (дополнительный)';
			|en = 'Person responsible for vendor rebate parameters (additional)'; fa = 'Person responsible for vendor rebate parameters (additional)';
			|it = 'Ответственный за параметры ретро-бонусов поставщиков (дополнительный)';
			|pl = 'Person responsible for vendor rebate parameters (additional)';
			|tr = 'Tedarikçilerin retro bonuslarının parametrelerinden sorumludur (ek)'",
			 Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("vi = 'Hồ sơ cấp quyền thay đổi dạng thưởng lũy kế của nhà cung cấp.
			 |Cần ấn định bổ sung đến hồ sơ khác bất kỳ có quyền đăng nhập vào hệ thống.';
			 |ru = 'Профиль предоставляет права на изменение видов ретро-бонусов поставщиков.
			 |Должен быть назначен в дополнение к любому другому профилю с правом входа в систему.';
			 |en = 'The profile grants the right to change vendor rebate kinds.
			 |It must be assigned in addition to any other profile with authorization rights.'; fa = 'The profile grants the right to change vendor rebate kinds.
			 |It must be assigned in addition to any other profile with authorization rights.';
			 |it = 'Профиль предоставляет права на изменение видов ретро-бонусов поставщиков.
			 |Должен быть назначен в дополнение к любому другому профилю с правом входа в систему.';
			 |pl = 'The profile grants the right to change vendor rebate kinds.
			 |It must be assigned in addition to any other profile with authorization rights.';
			 |tr = 'Профиль предоставляет права на изменение видов ретро-бонусов поставщиков.
			 |Должен быть назначен в дополнение к любому другому профилю с правом входа в систему.'",
			 Common.DefaultLanguageCode());
	
	SupplementProfileWithReadingRolesOfRebateKindOfSuppliers(ProfileDetails);
	
	ProfileDetails.Roles.Add("AddEditVendorRebateTypes");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddProfileManagerRebatesSuppliers(ProfilesDetails, ParametersOfUpdate)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name = "SupplierRebateManager";
	ProfileDetails.Id = "985bb178-f7df-4f9d-bf19-f61d5449a9c7";
	ProfileDetails.Parent = "ProcurementAndInventory";
	ProfileDetails.Description =
		NStr("vi = 'Người quản lý thưởng lũy kế của nhà cung cấp (bổ sung)';
			|ru = 'Менеджер ретро-бонусов поставщиков (дополнительный)';
			|en = 'Manager of vendor rebates (additional)'; fa = 'Manager of vendor rebates (additional)';
			|it = 'Менеджер ретро-бонусов поставщиков (дополнительный)';
			|pl = 'Manager of vendor rebates (additional)';
			|tr = 'Tedarikçi primleri yöneticisi (ek)'",
			 Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("vi = 'Hồ sơ cấp quyền ghi nhận điều kiện, tính toán, ghi giảm thưởng lũy kế của nhà cung cấp.
			 |Cần ấn định bổ sung vào hồ sơ người quản lý mua hàng.';
			 |ru = 'Профиль предоставляет права ведения условий, начислений, списаний ретро-бонусов поставщиков.
			 |Должен быть назначен в дополнение к профилю менеджера по закупкам.';
			 |en = 'The profile grants the right to maintain conditions, accruals, and write-offs of vendor rebates.
			 |It must be assigned in addition to the chief procurement officer profile.'; fa = 'The profile grants the right to maintain conditions, accruals, and write-offs of vendor rebates.
			 |It must be assigned in addition to the chief procurement officer profile.';
			 |it = 'Профиль предоставляет права ведения условий, начислений, списаний ретро-бонусов поставщиков.
			 |Должен быть назначен в дополнение к профилю менеджера по закупкам.';
			 |pl = 'The profile grants the right to maintain conditions, accruals, and write-offs of vendor rebates.
			 |It must be assigned in addition to the chief procurement officer profile.';
			 |tr = 'Профиль предоставляет права ведения условий, начислений, списаний ретро-бонусов поставщиков.
			 |Должен быть назначен в дополнение к профилю менеджера по закупкам.'",
			 Common.DefaultLanguageCode());
	
	SupplementProfileWithReadingRolesOfRebateKindOfSuppliers(ProfileDetails);
	
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadMasterData");
	
	ProfileDetails.Roles.Add("AddEditConditionsOfVendorRebates");
	ProfileDetails.Roles.Add("AddEditAccrualsOfVendorRebates");
	ProfileDetails.Roles.Add("ViewVendorRebateStatementReport");
	ProfileDetails.Roles.Add("ViewCalculateVendorRebatesReport");
	ProfileDetails.Roles.Add("AddEditWriteOffVendorRebates");
	
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddProfileOfMemberOfAgreementOfTermsOfRebatesOfSuppliers(ProfilesDetails, ParametersOfUpdate)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name = "MemberOfAgreementOnTermsOfRebateOfVendorsVBonuses";
	ProfileDetails.Id = "f8442f04-da40-4257-8bc5-85cffbcf9b90";
	ProfileDetails.Parent = "ProcurementAndInventory";
	ProfileDetails.Description =
		NStr("vi = 'Người tham gia thống nhất điều kiện thưởng lũy kế của nhà cung cấp (bổ sung)';
			|ru = 'Участник согласования условий ретро-бонусов поставщиков (дополнительный)';
			|en = 'Employee approving conditions of vendor rebates (additional)'; fa = 'Employee approving conditions of vendor rebates (additional)';
			|it = 'Участник согласования условий ретро-бонусов поставщиков (дополнительный)';
			|pl = 'Employee approving conditions of vendor rebates (additional)';
			|tr = 'Tedarikçi retro bonusu şartları anlaşmasının katılımcısı (ek)'",
			 Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("vi = 'Hồ sơ cấp quyền thống nhất trực tiếp cho chứng từ điều kiện thưởng lũy kế của nhà cung cấp.
			 |Cần ấn định bổ sung vào hồ sơ ""Người quản lý thưởng lũy kế của nhà cung cấp (bổ sung)""';
			 |ru = 'Профиль предоставляет право непосредственного согласования документ условий ретро-бонусов поставщиков.
			 |Должен быть назначен в дополнение к профилю ""Менеджер ретро-бонусов поставщиков (дополнительный)""';
			 |en = 'The profile grants the right to approve the vendor rebate conditions document.
			 |It must be assigned in addition to the ""Manager of vendor rebates (additional)"" profile'; fa = 'The profile grants the right to approve the vendor rebate conditions document.
			 |It must be assigned in addition to the ""Manager of vendor rebates (additional)"" profile';
			 |it = 'Профиль предоставляет право непосредственного согласования документ условий ретро-бонусов поставщиков.
			 |Должен быть назначен в дополнение к профилю ""Менеджер ретро-бонусов поставщиков (дополнительный)""';
			 |pl = 'The profile grants the right to approve the vendor rebate conditions document.
			 |It must be assigned in addition to the ""Manager of vendor rebates (additional)"" profile';
			 |tr = 'Profil, tedarikçi retro bonus hüküm ve koşulları belgesini doğrudan anlaşma yetkisini tanılamaktadır.
			 | ""Tedarikçi primleri yöneticisi (ek)"" profiline ek olarak atanmalıdır'",
			 Common.DefaultLanguageCode());
	
	ProfileDetails.Roles.Add("RightToApproveConditionsOfVendorRebates");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddProfileResponsibleForSupplierPremiumCertificatesAdditional(ProfilesDetails, ParametersOfUpdate)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name = "ResponsibleActsOfVendorPremiumsAdditional";
	ProfileDetails.Id = "8dd4a055-22ac-484d-849c-0a300847a924";
	ProfileDetails.Parent = "ProcurementAndInventory";
	ProfileDetails.Description =
		NStr("vi = 'Người chịu trách nhiệm về biên bản thưởng của nhà cung cấp (bổ sung)';
			|ru = 'Ответственный за акты премий поставщика (дополнительный)';
			|en = 'Person responsible for vendor bonus certificates (additional)'; fa = 'Person responsible for vendor bonus certificates (additional)';
			|it = 'Ответственный за акты премий поставщика (дополнительный)';
			|pl = 'Person responsible for vendor bonus certificates (additional)';
			|tr = 'Tedarikçilere yönelik ikramiye eylemlerinden sorumludur (ek)'",
			 Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("vi = 'Hồ sơ cấp quyền tạo thưởng của nhà cung cấp.
			 |Cần ấn định bổ sung vào hồ sơ ""Người quản lý thưởng lũy kế của nhà cung cấp (bổ sung)""';
			 |ru = 'Профиль предоставляет право оформления актов премий поставщика.
			 |Должен быть назначен в дополнение к профилю ""Менеджер ретро-бонусов поставщика (дополнительный)""';
			 |en = 'The profile grants the right to issue vendor bonus certificates.
			 |It must be assigned in addition to the ""Manager of vendor rebates (additional)"" profile'; fa = 'The profile grants the right to issue vendor bonus certificates.
			 |It must be assigned in addition to the ""Manager of vendor rebates (additional)"" profile';
			 |it = 'Профиль предоставляет право оформления актов премий поставщика.
			 |Должен быть назначен в дополнение к профилю ""Менеджер ретро-бонусов поставщика (дополнительный)""';
			 |pl = 'The profile grants the right to issue vendor bonus certificates.
			 |It must be assigned in addition to the ""Manager of vendor rebates (additional)"" profile';
			 |tr = 'Профиль предоставляет право оформления актов премий поставщика.
			 |Должен быть назначен в дополнение к профилю ""Менеджер ретро-бонусов поставщика (дополнительный)""'",
			 Common.DefaultLanguageCode());
	
	ProfileDetails.Roles.Add("AddEditVendorBonusCertificate");
	
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddProfileRightToDisableControlOfBalancesOfRebatesAdditional(ProfilesDetails, ParametersOfUpdate)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name = "RightToDisableControlOfBalancesOfRebatesIsAdditionalOne";
	ProfileDetails.Id = "17126a31-a792-4be6-92b9-6a5451248c79";
	ProfileDetails.Parent = "Sales";
	ProfileDetails.Description =
		NStr("vi = 'Quyền vô hiệu hóa kiểm soát số dư thưởng lũy kế của khách hàng (bổ sung)';
			|ru = 'Право отключения контроля остатков ретро-бонусов клиентов (дополнительный)';
			|en = 'Right to disable customer rebate balance check (additional)'; fa = 'Right to disable customer rebate balance check (additional)';
			|it = 'Право отключения контроля остатков ретро-бонусов клиентов (дополнительный)';
			|pl = 'Right to disable customer rebate balance check (additional)';
			|tr = 'Müşteri retro bonusu bakiyelerinin kontrolünü devre dışı bırakma yetkisi (ek)'",
			 Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("vi = 'Hồ sơ cấp quyền tắt sử dụng kiểm soát số dư thưởng lũy kế của khách hàng.
			 |
			 |Được ấn định bổ sung vào hồ sơ ""Người quản lý thưởng lũy kế cho khách hàng (bổ sung)"" hoặc ""Người chịu trách nhiệm thông báo thưởng cho khách hàng (bổ sung)""';
			 |ru = 'Профиль предоставляет право отключения контроля остатков ретро-бонусов клиентов.
			 |
			 |Назначается в дополнение к профилю ""Менеджер ретро-бонусов клиентов (дополнительный)"" или ""Ответственный за акты премий клиентам (дополнительный)""';
			 |en = 'The profile grants the right to disable customer rebate balance check.
			 |
			 |It is assigned in addition to the ""Manager of customer rebates (additional)"" or ""Person responsible for customer bonus certificates (additional)"" profile'; fa = 'The profile grants the right to disable customer rebate balance check.
			 |
			 |It is assigned in addition to the ""Manager of customer rebates (additional)"" or ""Person responsible for customer bonus certificates (additional)"" profile';
			 |it = 'Профиль предоставляет право отключения контроля остатков ретро-бонусов клиентов.
			 |
			 |Назначается в дополнение к профилю ""Менеджер ретро-бонусов клиентов (дополнительный)"" или ""Ответственный за акты премий клиентам (дополнительный)""';
			 |pl = 'The profile grants the right to disable customer rebate balance check.
			 |
			 |It is assigned in addition to the ""Manager of customer rebates (additional)"" or ""Person responsible for customer bonus certificates (additional)"" profile';
			 |tr = 'Bu profil, retro bonus bakiyelerinin kontrolünü devre dışı bırakma hakkı verir.
			 |
			 |""Müşteri retro bonusları yöneticisi (ek)"" veya ""Müşteri bonuslarından sorumlu (ek)"" profiline ek olarak atanır'",
			 Common.DefaultLanguageCode());
	
	ProfileDetails.Roles.Add("AllowDisablingCustomerRebateBalanceCheckForSessionDuration");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

#EndRegion

#Region FixingCompositionOfDocuments

// Parameters:
//  TermDocument - DocumentRef.ConditionsOfCustomerRebates
//  AccordingToDocument - Boolean
// 
// Returns:
//  ValueTable:
// * Products - CatalogRef.Products
// * Characteristic - CatalogRef.ItemsCharacteristics
//
Function FillInDataForFixingGoodsSegments(TermDocument, AccordingToDocument = False) Export
	
	ItemsTypes = SupportedItemTypes();
	
	ManagerOfDocument = Common.ObjectManagerByRef(TermDocument);
	QueryText = ManagerOfDocument.QueryTextForFixingItemSegments(AccordingToDocument);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("TermDocument", TermDocument);
	Query.SetParameter("SupportedItemTypes", ItemsTypes);
	
	QueryResults = Query.ExecuteBatch();
	ResultIsStaticSegments = QueryResults[1];
	ResultIsDynamicSegments = QueryResults[2];
	
	ItemOfSegments = NewTableOfSegmentItems();
		
	If Not ResultIsStaticSegments.IsEmpty() Then
		
		Selection = ResultIsStaticSegments.Select();
		FillInDataForFixingStaticSegments(Selection, ItemOfSegments);
		
	EndIf;
	
	If Not ResultIsDynamicSegments.IsEmpty() Then
		
		Selection = ResultIsDynamicSegments.Select();
		FillInDataForFixingDynamicGoodsSegments(
			Selection,
			ItemOfSegments);
			
	EndIf;
	
	Return ItemOfSegments;
	
EndFunction

// Parameters:
//  TermDocument - DocumentRef.ConditionsOfCustomerRebates
//  AccordingToDocument - Boolean
// 
// Returns:
//  ValueTable:
// * Partner - CatalogRef.Partners
//
Function FillInDataForFixingPartnerSegments(TermDocument, AccordingToDocument = False) Export
	
	Query = New Query;
	Query.Text = QueryTextForFixingPartnerSegments(AccordingToDocument);
	Query.SetParameter("TermDocument", TermDocument);
	
	QueryResults = Query.ExecuteBatch();
	ResultIsStaticSegments = QueryResults[1];
	ResultIsDynamicSegments = QueryResults[2];
	
	SegmentsPartners = NewTableOfPartnersSegments();
	
	If Not ResultIsStaticSegments.IsEmpty() Then
		
		Selection = ResultIsStaticSegments.Select();
		FillInDataForFixingStaticSegments(Selection, SegmentsPartners);
		
	EndIf;
	
	If Not ResultIsDynamicSegments.IsEmpty() Then
		
		Selection = ResultIsDynamicSegments.Select();
		FillInDataForFixingDynamicPartnerSegments(Selection, SegmentsPartners);
		
	EndIf;
	
	Return SegmentsPartners;
	
EndFunction

Function QueryTextForFixingPartnerSegments(AccordingToDocument)
	
	QueriesArray = New Array; // Array of String
	
	If AccordingToDocument Then
		
		QueryText =
		"SELECT
		|	ConditionsOfCustomerRebatesPartnersSegments.Segment AS Segment,
		|	ConditionsOfCustomerRebatesPartnersSegments.Segment.GenerationMethod AS GenerationMethod
		|INTO TT_Segments
		|FROM
		|	Document.ConditionsOfCustomerRebates.PartnersSegments AS ConditionsOfCustomerRebatesPartnersSegments
		|WHERE
		|	ConditionsOfCustomerRebatesPartnersSegments.Ref = &TermDocument
		|	AND NOT ConditionsOfCustomerRebatesPartnersSegments.Canceled";
		
	Else
		
		QueryText =
		"SELECT DISTINCT
		|	PartnersSegments.Segment AS Segment,
		|	PartnersSegments.Segment.GenerationMethod AS GenerationMethod
		|INTO TT_Segments
		|FROM
		|	InformationRegister.CustomerRebatesPartnerSegments AS PartnersSegments
		|WHERE
		|	PartnersSegments.TermDocument = &TermDocument
		|
		|INDEX BY
		|	Segment";
		
	EndIf;
	
	QueriesArray.Add(QueryText);
	
	QueryText =
	"SELECT DISTINCT
	|	SegmentPartners.Partner AS Partner
	|FROM
	|	TT_Segments AS TT_Segments
	|		INNER JOIN InformationRegister.SegmentPartners AS SegmentPartners
	|		ON TT_Segments.Segment = SegmentPartners.Segment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Segments.Segment AS Segment
	|FROM
	|	TT_Segments AS TT_Segments
	|WHERE
	|	TT_Segments.GenerationMethod = VALUE(Enum.SegmentGenerationMethods.GenerateDynamically)";
	
	QueriesArray.Add(QueryText);
	QueryText = StrConcat(QueriesArray, Common.QueryBatchSeparator());
	
	Return QueryText;
	
EndFunction

// Parameters:
//  Selection - QueryResultSelection:
//  DataTableOfSegments - ValueTable
//
Procedure FillInDataForFixingStaticSegments(Selection, DataTableOfSegments)
	
	While Selection.Next() Do
		
		SegmentData = DataTableOfSegments.Add();
		FillPropertyValues(SegmentData, Selection);
		
	EndDo;
	
EndProcedure

// Parameters:
//  Selection - QueryResultSelection:
//  * Segment - CatalogRef.ProductSegments
//  DataTableOfSegments - See RebatesServer.
//
Procedure FillInDataForFixingDynamicGoodsSegments(Selection, DataTableOfSegments)
	
	ItemListOfDynamicSegments = NewTableOfSegmentItems();
	
	While Selection.Next() Do
		
		TableOfSegment = DynamicItemSegmentTable(Selection.Segment);
		ColumnCharacteristics = TableOfSegment.Columns.Find("ElementCharacteristics");
		
		For Each SegmentTableRow In TableOfSegment Do
			
			SegmentData = ItemListOfDynamicSegments.Add();
			SegmentData.Products = SegmentTableRow.ListItem;
			
			If ColumnCharacteristics <> Undefined Then
				
				SegmentData.Characteristic = SegmentTableRow.ElementCharacteristics;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	QueryText =
	"SELECT DISTINCT
	|	CAST(ItemOfSegments.Products AS Catalog.Products) AS Products,
	|	ItemOfSegments.Characteristic AS Characteristic
	|INTO TT_ItemOfSegments
	|FROM
	|	&ItemOfSegments AS ItemOfSegments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_ItemOfSegments.Products AS Products,
	|	TT_ItemOfSegments.Characteristic AS Characteristic
	|FROM
	|	TT_ItemOfSegments AS TT_ItemOfSegments
	|WHERE
	|	TT_ItemOfSegments.Products.ItemsType IN (&SupportedItemTypes)";
	
	ItemsTypes = SupportedItemTypes();
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ItemOfSegments", ItemListOfDynamicSegments);
	Query.SetParameter("SupportedItemTypes", ItemsTypes);
	
	ResultSegmentComposition = Query.Execute();
	If Not ResultSegmentComposition.IsEmpty() Then
		
		Selection = ResultSegmentComposition.Select();
		While Selection.Next() Do
			
			SegmentData = DataTableOfSegments.Add();
			FillPropertyValues(SegmentData, Selection);
			
		EndDo;
		
	EndIf;
	
	DataTableOfSegments.GroupBy("Products, Characteristic");
	
EndProcedure

// Parameters:
//  Selection - QueryResultSelection:
//  * Segment - CatalogRef.PartnersSegments
//  DataTableOfSegments - See NewTableOfPartnersSegments
//
Procedure FillInDataForFixingDynamicPartnerSegments(Selection, DataTableOfSegments)
	
	While Selection.Next() Do
		
		TableOfSegment = DynamicPartnerSegmentTable(Selection.Segment);
		For Each SegmentTableRow In TableOfSegment Do
			
			SegmentData = DataTableOfSegments.Add();
			SegmentData.Partner = SegmentTableRow.ListItem;
			
		EndDo;
		
	EndDo;
	
	DataTableOfSegments.GroupBy("Partner");
	
EndProcedure

// Returns:
//  ValueTable - New Table of Segment Items:
//  * Products - CatalogRef.Products
//  * Characteristic - CatalogRef.ItemsCharacteristics
Function NewTableOfSegmentItems()
	
	DescriptionOfItemTypes = New TypeDescription("CatalogRef.Products");
	DescriptionOfTypesCharacteristic = New TypeDescription("CatalogRef.ItemsCharacteristics");
	
	ItemOfSegments = New ValueTable();
	ItemOfSegments.Columns.Add("Products", DescriptionOfItemTypes);
	ItemOfSegments.Columns.Add("Characteristic", DescriptionOfTypesCharacteristic);
	
	Return ItemOfSegments;
	
EndFunction

// Returns:
//  ValueTable - New Table of Segment Items:
//  * Partner - CatalogRef.Partners
Function NewTableOfPartnersSegments()
	
	DescriptionOfPartnerTypes = New TypeDescription("CatalogRef.Partners");
	
	SegmentsPartners = New ValueTable();
	SegmentsPartners.Columns.Add("Partner", DescriptionOfPartnerTypes);
	
	Return SegmentsPartners;
	
EndFunction

// Parameters:
//  Segment - CatalogRef.ProductSegments
// 
// Returns:
//  ValueTable:
//  * ListItem - CatalogRef.Products
//  * ElementCharacteristics - CatalogRef.ItemsCharacteristics
Function DynamicItemSegmentTable(Segment)
	
	TableOfSegment = SegmentsServer.ListOfDCSElements(Segment);
	Return TableOfSegment;
	
EndFunction

// Parameters:
//  Segment - CatalogRef.PartnersSegments
// 
// Returns:
//  ValueTable:
//  * ListItem - CatalogRef.Partners
Function DynamicPartnerSegmentTable(Segment)
	
	TableOfSegment = SegmentsServer.ListOfDCSElements(Segment);
	Return TableOfSegment;
	
EndFunction

// Parameters:
//  Document - DocumentRef.ConditionsOfCustomerRebates , DocumentRef.ConditionsOfVendorRebates -
// 
// Returns:
//  ValueTable:
//  * ValidOnDate - Date
//  * ValidTo - Date
//  * TermDocument - DocumentRef.ConditionsOfCustomerRebates, DocumentRef.ConditionsOfVendorRebates -
//  * Products - CatalogRef.Products
//  * Characteristic - CatalogRef.ItemsCharacteristics
//  * CountPlan - Number
//  * BonusPercent - Number
//  * BasePrice - Number
//  * RecorderDocument - DocumentRef.ConditionsOfCustomerRebates, DocumentRef.ConditionsOfVendorRebates -
//  * DocumentRowNumber - Number -
//
Function NewCompositionOfGoodsSegments(Document)
	
	DocumentType = TypeOf(Document);
	ArrayOfDocumentTypes = CommonClientServer.ValueInArray(DocumentType);
	
	DateTypeDetails = Common.DateTypeDetails(DateFractions.Date);
	TypeDescriptionNumber15_3 = Common.TypeDescriptionNumber(15, 3, AllowedSign.Nonnegative);
	TypeDescriptionNumber4_2 = Common.TypeDescriptionNumber(4, 2, AllowedSign.Nonnegative);
	TypeDescriptionNumber5_0 = Common.TypeDescriptionNumber(5, 0, AllowedSign.Nonnegative);
	DescriptionOfConditionsDocumentType = New TypeDescription(ArrayOfDocumentTypes);
	DescriptionOfItemType = New TypeDescription("CatalogRef.Products");
	DescriptionOfCharacteristicType = New TypeDescription("CatalogRef.ItemsCharacteristics");
	
	TableOfSegmentComposition = New ValueTable();
	TableOfSegmentComposition.Columns.Add("ValidOnDate", DateTypeDetails);
	TableOfSegmentComposition.Columns.Add("ValidTo", DateTypeDetails);
	TableOfSegmentComposition.Columns.Add("TermDocument", DescriptionOfConditionsDocumentType);
	TableOfSegmentComposition.Columns.Add("Products", DescriptionOfItemType);
	TableOfSegmentComposition.Columns.Add("Characteristic", DescriptionOfCharacteristicType);
	TableOfSegmentComposition.Columns.Add("CountPlan", TypeDescriptionNumber15_3);
	TableOfSegmentComposition.Columns.Add("BonusPercent", TypeDescriptionNumber4_2);
	TableOfSegmentComposition.Columns.Add("BasePrice", Metadata.DefinedTypes.Price.Type);
	TableOfSegmentComposition.Columns.Add("RecorderDocument", DescriptionOfConditionsDocumentType);
	TableOfSegmentComposition.Columns.Add("DocumentRowNumber", TypeDescriptionNumber5_0);
	
	Return TableOfSegmentComposition;
	
EndFunction

// Parameters:
//  Document - DocumentRef.ConditionsOfCustomerRebates , DocumentRef.ConditionsOfVendorRebates -
// 
// Returns:
//  ValueTable:
//  * ValidOnDate - Date
//  * ValidTo - Date
//  * TermDocument - DocumentRef.ConditionsOfCustomerRebates, DocumentRef.ConditionsOfVendorRebates -
//  * Products - CatalogRef.Products
//  * Characteristic - CatalogRef.ItemsCharacteristics
//  * CountPlan - Number
//  * BonusPercent - Number
//  * BasePrice - Number
//  * QuantityPlanRangeBound - Number
//  * RecorderDocument - DocumentRef.ConditionsOfCustomerRebates, DocumentRef.ConditionsOfVendorRebates -
//  * DocumentRowNumber - Number -
//  * PropertyValue - DefinedType.RebateItemPropertyTypes
//
Function NewCompositionOfItemProperties(Document)
	
	DocumentType = TypeOf(Document);
	ArrayOfDocumentTypes = CommonClientServer.ValueInArray(DocumentType);
	
	DateTypeDetails = Common.DateTypeDetails(DateFractions.Date);
	TypeDescriptionNumber15_3 = Common.TypeDescriptionNumber(15, 3, AllowedSign.Nonnegative);
	TypeDescriptionNumber4_2 = Common.TypeDescriptionNumber(4, 2, AllowedSign.Nonnegative);
	TypeDescriptionNumber5_0 = Common.TypeDescriptionNumber(5, 0, AllowedSign.Nonnegative);
	DescriptionOfConditionsDocumentType = New TypeDescription(ArrayOfDocumentTypes);
	DescriptionOfItemType = New TypeDescription("CatalogRef.Products");
	DescriptionOfCharacteristicType = New TypeDescription("CatalogRef.ItemsCharacteristics");
	DescriptionOfPropertyType = Metadata.DefinedTypes.RebateItemPropertyTypes.Type;
	
	TableOfCompositionOfProperties = New ValueTable();
	TableOfCompositionOfProperties.Columns.Add("ValidOnDate", DateTypeDetails);
	TableOfCompositionOfProperties.Columns.Add("ValidTo", DateTypeDetails);
	TableOfCompositionOfProperties.Columns.Add("TermDocument", DescriptionOfConditionsDocumentType);
	TableOfCompositionOfProperties.Columns.Add("Products", DescriptionOfItemType);
	TableOfCompositionOfProperties.Columns.Add("Characteristic", DescriptionOfCharacteristicType);
	TableOfCompositionOfProperties.Columns.Add("CountPlan", TypeDescriptionNumber15_3);
	TableOfCompositionOfProperties.Columns.Add("BonusPercent", TypeDescriptionNumber4_2);
	TableOfCompositionOfProperties.Columns.Add("BasePrice", Metadata.DefinedTypes.Price.Type);
	TableOfCompositionOfProperties.Columns.Add("QuantityPlanRangeBound", TypeDescriptionNumber15_3);
	TableOfCompositionOfProperties.Columns.Add("RecorderDocument", DescriptionOfConditionsDocumentType);
	TableOfCompositionOfProperties.Columns.Add("DocumentRowNumber", TypeDescriptionNumber5_0);
	TableOfCompositionOfProperties.Columns.Add("PropertyValue", DescriptionOfPropertyType);
	
	Return TableOfCompositionOfProperties;
	
EndFunction

// Parameters:
//  SegmentsPartners - See NewTableOfPartnersSegments
Procedure SortPartnerSegmentTableByPresentation(SegmentsPartners)
	
	QueryText =
	"SELECT
	|	CAST(SegmentsPartners.Partner AS Catalog.Partners) AS Partner
	|INTO TT_SegmentsPartners
	|FROM
	|	&SegmentsPartners AS SegmentsPartners
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_SegmentsPartners.Partner AS Partner
	|FROM
	|	TT_SegmentsPartners AS TT_SegmentsPartners
	|
	|ORDER BY
	|	TT_SegmentsPartners.Partner
	|AUTOORDER";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("SegmentsPartners", SegmentsPartners);
	
	SegmentsPartners = Query.Execute().Unload();
	
EndProcedure

// Parameters:
//  ItemOfSegments - See NewTableOfSegmentItems
Procedure SortItemSegmentTableByPresentation(ItemOfSegments)
	
	QueryText =
	"SELECT
	|	CAST(ItemOfSegments.Products AS Catalog.Products) AS Products,
	|	CAST(ItemOfSegments.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic
	|INTO TT_ItemOfSegments
	|FROM
	|	&ItemOfSegments AS ItemOfSegments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_ItemOfSegments.Products AS Products,
	|	TT_ItemOfSegments.Characteristic AS Characteristic
	|FROM
	|	TT_ItemOfSegments AS TT_ItemOfSegments
	|
	|ORDER BY
	|	TT_ItemOfSegments.Products,
	|	TT_ItemOfSegments.Characteristic
	|AUTOORDER";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ItemOfSegments", ItemOfSegments);
	
	ItemOfSegments = Query.Execute().Unload();
	
EndProcedure

// Returns a table of products selected by the item property corresponding to the structure of the PC retrobonusiclient Products
//
// Parameters:
//  Document - DocumentRef.ConditionsOfCustomerRebates -
//           - DocumentRef.ConditionsOfVendorRebates -
// 
// Returns:
//  See NewCompositionOfItemProperties
//
Function CompositionOfItemsByProperty(Document)
	
	If TypeOf(Document) = Type("DocumentRef.ConditionsOfCustomerRebates") Then
		
		RebateConditionsParameters = RebatesCalculation.ParametersOfTermsOfRebatesForCustomers(Document);
		CalculationOfCustomerBonuses = True;
		
	Else
		
		RebateConditionsParameters = RebatesCalculation.ParametersOfTermsOfRebatesOfSuppliers(Document);
		CalculationOfCustomerBonuses = False;
		
	EndIf;
	
	TextItemsByProperty = QueryTextItemsByProperty(
		CalculationOfCustomerBonuses,
		RebateConditionsParameters.ProductItemProperty,
		RebateConditionsParameters.ItemItemPropertyLink);
	
	TextCompositionOfItems =
	"SELECT
	|	ItemsByProperty.ValidOnDate AS ValidOnDate,
	|	ItemsByProperty.ValidTo AS ValidTo,
	|	ItemsByProperty.TermDocument AS TermDocument,
	|	ItemsByProperty.Products AS Products,
	|	ItemsByProperty.Characteristic AS Characteristic,
	|	ItemsByProperty.CountPlan AS CountPlan,
	|	ItemsByProperty.BonusPercent AS BonusPercent,
	|	ItemsByProperty.BasePrice AS BasePrice,
	|	ItemsByProperty.QuantityPlanRangeBound AS QuantityPlanRangeBound,
	|	ItemsByProperty.PropertyValue AS PropertyValue
	|FROM
	|	TT_ItemsByProperty AS ItemsByProperty
	|WHERE
	|	ItemsByProperty.Products.ItemsType IN (&SupportedItemTypes)
	|AUTOORDER";
	
	TextSeparator_ = Common.QueryBatchSeparator();
	
	FragmentsOfTheQuery = New Array; // Array of String
	FragmentsOfTheQuery.Add(TextItemsByProperty);
	FragmentsOfTheQuery.Add(TextCompositionOfItems);
	
	QueryText = StrConcat(FragmentsOfTheQuery, TextSeparator_);
	
	ItemsTypes = SupportedItemTypes();
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("SourceDocument_", Document);
	Query.SetParameter("ProductItemProperty", RebateConditionsParameters.ItemItemPropertyLink);
	Query.SetParameter("SupportedItemTypes", ItemsTypes);
	
	QueryResult = Query.Execute();
	
	ItemsByProperties = NewCompositionOfItemProperties(Document);
	
	ActualDocument = UpToDateDocumentOfRebatesTermsAndConditionsCanBeFoundAtLink(Document);
	If Not ActualDocument.IsEmpty()
	   And Not QueryResult.IsEmpty() Then
		
		Counter = 1;
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			NewRow = ItemsByProperties.Add();
			FillPropertyValues(NewRow, Selection);
			NewRow.RecorderDocument = ActualDocument;
			NewRow.DocumentRowNumber = Counter;
			
			Counter = Counter + 1;
			
		EndDo;
		
	EndIf;
	
	Return ItemsByProperties;
	
EndFunction

#EndRegion

#Region BatchProcessingOfStrings

Procedure BatchProcessingFillInIndicationOfCurrencyOfRebatesOfVendorsOfRetroBonuses(StructureOfActions, Cached_Values, SelectionFields1)
	
	Var ActionParameters; // Structure
	
	ActionIsRequired = BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInCurrencyIndicationForRebatesOfSuppliers",
		StructureOfActions,
		Cached_Values,
		ActionParameters);
	
	If ActionIsRequired Then
		
		SelectionField_Template =
		"CASE
		|	WHEN ISNULL(DataSource.%1, VALUE(Document.ConditionsOfVendorRebates.EmptyRef)) = VALUE(Document.ConditionsOfVendorRebates.EmptyRef)
		|		THEN FALSE
		|	ELSE
		|		DataSource.%1.Currency <> VALUE(Catalog.Currencies.EmptyRef)
		|END AS %2";
		
		For Each Field In ActionParameters Do // KeyAndValue
			SelectionField = StrTemplate(SelectionField_Template, Field.Key, Field.Value);
		EndDo;
		
		SelectionFields1.Add(SelectionField);
		
	EndIf;
	
EndProcedure

Procedure BatchProcessingToFillInCurrencyOfSuppliersRebates(StructureOfActions, Cached_Values, SelectionFields1)
	
	Var ActionParameters; // Structure
	
	ActionIsRequired = BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInCurrencyOfVendorSRebates",
		StructureOfActions,
		Cached_Values,
		ActionParameters);
	
	If ActionIsRequired Then
		
		SelectionField_Template =
		"CASE
		|	WHEN ISNULL(DataSource.%1, VALUE(Document.ConditionsOfVendorRebates.EmptyRef)) = VALUE(Document.ConditionsOfVendorRebates.EmptyRef)
		|		THEN FALSE
		|	ELSE
		|		DataSource.%1.Currency
		|END AS %2";
		
		For Each Field In ActionParameters Do // KeyAndValue
			SelectionField = StrTemplate(SelectionField_Template, Field.Key, Field.Value);
		EndDo;
		
		SelectionFields1.Add(SelectionField);
		
	EndIf;
	
EndProcedure

Procedure BatchProcessingIsTypeOfRebateOfVendorTypeOf(StructureOfActions, Cached_Values, SelectionFields1)
	
	Var ActionParameters; // Structure
	
	ActionIsRequired = BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInRebateTypeOfSuppliers",
		StructureOfActions,
		Cached_Values,
		ActionParameters);
	
	If ActionIsRequired Then
		
		SelectionField_Template =
		"CASE
		|	WHEN ISNULL(DataSource.%1, VALUE(Document.ConditionsOfVendorRebates.EmptyRef)) = VALUE(Document.ConditionsOfVendorRebates.EmptyRef)
		|		THEN VALUE(Enum.VendorRebateTypes.EmptyRef)
		|	ELSE
		|		DataSource.%1.BonusType
		|END AS %2";
		
		For Each Field In ActionParameters Do // KeyAndValue
			SelectionField = StrTemplate(SelectionField_Template, Field.Key, Field.Value);
		EndDo;
		
		SelectionFields1.Add(SelectionField);
		
	EndIf;
	
EndProcedure

// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  Cached_Values - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure AddAgreementAttributeToQueryTextInTSLine(StructureOfActions, QueryDetails, Cached_Values)
	
	Var NameOfAgreementField; // String
	
	ActionIsRequired = BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInAgreementAttributeInTSLine",
		StructureOfActions,
		Cached_Values,
		NameOfAgreementField);
	
	If ActionIsRequired Then
		
		QueryText =
		"SELECT ALLOWED
		|	DataSource.IdOfTTRow AS IdOfTTRow,
		|	TermsOfSale.Standard_ AS ThisIsModelAgreement
		|FROM
		|	TTDataSource AS DataSource
		|		LEFT JOIN Catalog.TermsOfSale AS TermsOfSale
		|		ON &AgreementField_ = TermsOfSale.Ref";
		
		QueryText = StrReplace(QueryText, "&AgreementField_", "DataSource." + NameOfAgreementField);
		
		QueryDetails.QueriesTexts.Add(QueryText, "SignsOfAgreements");
		
	EndIf;
	
EndProcedure

// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  Cached_Values - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure AddQueryTextToRebatePropertiesOfSuppliersVBonuses(StructureOfActions, QueryDetails, Cached_Values)
	
	SelectionFields1 = New Array; // Array of String
	
	BatchProcessingFillInIndicationOfCurrencyOfRebatesOfVendorsOfRetroBonuses(
		StructureOfActions, Cached_Values, SelectionFields1);
	
	BatchProcessingToFillInCurrencyOfSuppliersRebates(
		StructureOfActions, Cached_Values, SelectionFields1);
	
	BatchProcessingIsTypeOfRebateOfVendorTypeOf(
		StructureOfActions, Cached_Values, SelectionFields1);
	
	If SelectionFields1.Count() > 0 Then
		
		QueryText =
		"SELECT ALLOWED
		|	DataSource.IdOfTTRow AS IdOfTTRow,
		|	&SelectionFields1
		|FROM
		|	TTDataSource AS DataSource";
		
		ConnectorForSelectionFields = Chars.LF + ",";
		SelectionFieldString_ = StrConcat(SelectionFields1, ConnectorForSelectionFields);
		QueryText = StrReplace(QueryText, "&SelectionFields1", SelectionFieldString_);
		
		QueryDetails.QueriesTexts.Add(QueryText, "PropertiesOfRebatesSuppliers");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ConditionalAppearanceCalculationScale

Procedure SetDesignCalculationScaleBonusPercentage(ConditionalAppearance)
	
	#Region ProgressiveScale
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("CalculationScalesBonusPercent");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CalculationScaleType");
	ItemFilter.RightValue = 1; // Progressive Scale
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CalculationScales.BonusPercent");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	#EndRegion
	
	#Region ByRanges
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("CalculationScalesBonusPercent");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CalculationScaleType");
	ItemFilter.RightValue = 2; // By Ranges
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CalculationScales.BonusPercent");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	StringZero = NStr("vi = '<không>';
						|ru = '<нет>';
						|en = '<no>'; fa = '<خیر>';
						|it = '<no>';
						|pl = '<no>';
						|tr = '<yok>'");
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", StringZero);
	#EndRegion
	
EndProcedure

Procedure SetDesignCalculationScaleRangeFrom(ConditionalAppearance)
	
	// Prohibition of changing the boundary 0 for ranges (initial value of the first range)
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("CalculationScalesRangeFrom");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CalculationScaleType");
	ItemFilter.RightValue = 2; // By Ranges
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CalculationScales.RangeFrom");
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CalculationScales.LineNumber");
	ItemFilter.RightValue = 1;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

#EndRegion

#Region CheckingStringPeriods

// Checking the start date of the retro bonus in the added line in relation to the maximum end date of the registered accrual period.
//  
// Parameters:
//  MaxDate - Date - Maximum end date of the registered accrual
//  TableName - String - table name
//  TablePresentation - String - Table Presentation
//  CurrentStartDate - Date - Start date in the added line
//  CurrentTableRow - DocumentTabularSectionRow.ConditionsOfVendorRebates.CustomerCounterparties, DocumentTabularSectionRow.ConditionsOfVendorRebates.ClientsCounterpartiesTIN, DocumentTabularSectionRow.ConditionsOfVendorRebates.Goods, DocumentTabularSection.ConditionsOfVendorRebates.ProductProperties_, DocumentTabularSectionRow.ConditionsOfVendorRebates.Vendors, DocumentTabularSectionRow.ConditionsOfCustomerRebates.Counterparties, DocumentTabularSectionRow.ConditionsOfCustomerRebates.CounterpartiesTIN, DocumentTabularSectionRow.ConditionsOfCustomerRebates.Goods, DocumentTabularSectionRow.ConditionsOfCustomerRebates.ContractsTermsOfSales, DocumentTabularSection.ConditionsOfCustomerRebates.ProductProperties_ - The Cur row of the table
//  Cancel - Boolean - Cancel
//
Procedure CheckValidityOfBeginningOfLinePeriod(Val MaxDate, Val TableName, Val TablePresentation, Val CurrentStartDate, CurrentTableRow, Cancel)
	
	If Not CurrentTableRow.InitialString
	   And CurrentStartDate <= MaxDate Then
		
		Template = NStr("vi = 'Tại dòng %1 danh sách ""%2"" ngày bắt đầu không thể nhỏ hơn hoặc bằng %3 - ngày cuối kỳ ghi nhận tính toán';
						|ru = 'В строке %1 списка ""%2"" дата начала не может быть меньше или равна %3 - даты окончания периода зарегистрированного начисления';
						|en = 'In line %1 of the ""%2"" list, the start date cannot be less than or equal to %3 - the end date of the registered accrual period'; fa = 'In line %1 of the ""%2"" list, the start date cannot be less than or equal to %3 - the end date of the registered accrual period';
						|it = 'В строке %1 списка ""%2"" дата начала не может быть меньше или равна %3 - даты окончания периода зарегистрированного начисления';
						|pl = 'In line %1 of the ""%2"" list, the start date cannot be less than or equal to %3 - the end date of the registered accrual period';
						|tr = '""%2"" liste%1satırında, başlangıç tarihi aşağıdakilerden küçük veya eşit olamaz:%3- kayıtlı tahakkuk döneminin bitiş tarihi'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			Template,
			String(CurrentTableRow.LineNumber),
			TablePresentation,
			Format(MaxDate, "DLF=D;"));
		
		Field = CommonClientServer.PathToTabularSection(
			TableName, CurrentTableRow.LineNumber, "ValidOnDate");
		
		Common.MessageToUser(MessageText,, Field, "Object", Cancel);
		
	EndIf;
	
EndProcedure

// Checking whether there is a change in the start date of the retro bonus in the source line during the registered accrual, when the start date of the retro bonus before the change was less than or equal to the maximum end date of the registered accrual period.
// 
// Parameters:
//  MaxDate - Date - Maximum end date of the registered accrual period
//  TableName - String - table name
//  TablePresentation - String - Table Presentation
//  CurrentStartDate - Date - Start date in the original line
//  CurrentTableRow - DocumentTabularSectionRow.ConditionsOfVendorRebates.CustomerCounterparties, DocumentTabularSectionRow.ConditionsOfVendorRebates.ClientsCounterpartiesTIN, DocumentTabularSectionRow.ConditionsOfVendorRebates.Goods, DocumentTabularSectionRow.ConditionsOfVendorRebates.Vendors, DocumentTabularSectionRow.ConditionsOfCustomerRebates.Counterparties, DocumentTabularSectionRow.ConditionsOfCustomerRebates.CounterpartiesTIN, DocumentTabularSectionRow.ConditionsOfCustomerRebates.Goods, DocumentTabularSectionRow.ConditionsOfCustomerRebates.ContractsTermsOfSales - The Cur row of the table
//  Cancel - Boolean - Cancel
//
Procedure CheckChangeBeginningOfPeriodOfOriginalString(Val MaxDate, Val TableName, Val TablePresentation, Val CurrentStartDate, CurrentTableRow, Cancel)
	
	If CurrentTableRow.InitialString
	   And Not CurrentTableRow.Canceled
	   And CurrentTableRow.StartDateBeforeChange <> Date(1, 1, 1)
	   And CurrentTableRow.StartDateBeforeChange <= MaxDate
	   And CurrentStartDate <> CurrentTableRow.StartDateBeforeChange Then
		
		Template = NStr("vi = 'Tại dòng %1 danh sách ""%2"" không thể thay đổi ngày bắt đầu, bởi vì trong kỳ hiệu lực điều kiện đã được ghi nhận tính toán';
						|ru = 'В строке %1 списка ""%2"" дата начала не может быть изменена, так как в период действия условия были зарегистрированы начисления';
						|en = 'In line %1 of the ""%2"" list, the start date cannot be changed as accruals were registered during the condition validity period'; fa = 'In line %1 of the ""%2"" list, the start date cannot be changed as accruals were registered during the condition validity period';
						|it = 'В строке %1 списка ""%2"" дата начала не может быть изменена, так как в период действия условия были зарегистрированы начисления';
						|pl = 'In line %1 of the ""%2"" list, the start date cannot be changed as accruals were registered during the condition validity period';
						|tr = '""%2"" listesinin %1 satırında, tahakkukların şartlar döneminde kaydedilmesinden dolayı başlangıç tarihi değiştirilemez'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			Template,
			String(CurrentTableRow.LineNumber),
			TablePresentation);
		
		Field = CommonClientServer.PathToTabularSection(
			TableName, CurrentTableRow.LineNumber, "ValidOnDate");
		
		Common.MessageToUser(MessageText,, Field, "Object", Cancel);
		
	EndIf;
	
EndProcedure

// Checking the start date of the retro bonus in the source line in relation to the maximum end date of the registered accrual period, when the start date of the retro bonus before the change was greater than the maximum end date of the registered accrual period.
// 
// Parameters:
//  MaxDate - Date - Maximum end date of the registered accrual period
//  TableName - String - table name
//  TablePresentation - String - Table Presentation
//  CurrentStartDate - Date - Start date in the original line
//  CurrentTableRow - DocumentTabularSectionRow.ConditionsOfVendorRebates.CustomerCounterparties, DocumentTabularSectionRow.ConditionsOfVendorRebates.ClientsCounterpartiesTIN, DocumentTabularSectionRow.ConditionsOfVendorRebates.Goods, DocumentTabularSectionRow.ConditionsOfVendorRebates.Vendors, DocumentTabularSectionRow.ConditionsOfCustomerRebates.Counterparties, DocumentTabularSectionRow.ConditionsOfCustomerRebates.CounterpartiesTIN, DocumentTabularSectionRow.ConditionsOfCustomerRebates.Goods, DocumentTabularSectionRow.ConditionsOfCustomerRebates.ContractsTermsOfSales - The Cur row of the table
//  Cancel - Boolean - Cancel
//
Procedure CheckValidityOfBeginningOfPeriodOfSourceString(Val MaxDate, Val TableName, Val TablePresentation, Val CurrentStartDate, CurrentTableRow, Cancel)
	
	If CurrentTableRow.InitialString
	   And Not CurrentTableRow.Canceled
	   And CurrentTableRow.StartDateBeforeChange > MaxDate
	   And CurrentStartDate <= MaxDate Then
		
		Template = NStr("vi = 'Tại dòng %1 danh sách ""%2"" ngày bắt đầu không thể nhỏ hơn hoặc bằng %3 - ngày cuối kỳ ghi nhận tính toán';
						|ru = 'В строке %1 списка ""%2"" дата начала не может меньше или равной %3 - даты окончания периода зарегистрированного начисления';
						|en = 'In line %1 of the ""%2"" list, the start date cannot be less than or equal to %3 - the end date of the registered accrual period'; fa = 'In line %1 of the ""%2"" list, the start date cannot be less than or equal to %3 - the end date of the registered accrual period';
						|it = 'В строке %1 списка ""%2"" дата начала не может меньше или равной %3 - даты окончания периода зарегистрированного начисления';
						|pl = 'In line %1 of the ""%2"" list, the start date cannot be less than or equal to %3 - the end date of the registered accrual period';
						|tr = '""%2"" liste%1satırında, başlangıç tarihi aşağıdakilerden küçük veya eşit olamaz:%3- kayıtlı tahakkuk döneminin bitiş tarihi'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			Template,
			String(CurrentTableRow.LineNumber),
			TablePresentation,
			Format(MaxDate, "DLF=D;"));
		
		Field = CommonClientServer.PathToTabularSection(
			TableName, CurrentTableRow.LineNumber, "ValidOnDate");
		
		Common.MessageToUser(MessageText,, Field, "Object", Cancel);
		
	EndIf;
	
EndProcedure

// Checking the expiration date of the retro bonus in the added line in relation to the maximum end date of the registered accrual period.
// 
// Parameters:
//  MaxDate - Date - Maximum end date of the registered accrual
//  TableName - String - table name
//  TablePresentation - String - Table Presentation
//  CurrentEndDate - Date - End date in the added line
//  CurrentTableRow - DocumentTabularSectionRow.ConditionsOfVendorRebates.CustomerCounterparties, DocumentTabularSectionRow.ConditionsOfVendorRebates.ClientsCounterpartiesTIN, DocumentTabularSectionRow.ConditionsOfVendorRebates.Goods, DocumentTabularSectionRow.ConditionsOfVendorRebates.Vendors, DocumentTabularSectionRow.ConditionsOfCustomerRebates.Counterparties, DocumentTabularSectionRow.ConditionsOfCustomerRebates.CounterpartiesTIN, DocumentTabularSectionRow.ConditionsOfCustomerRebates.Goods, DocumentTabularSectionRow.ConditionsOfCustomerRebates.ContractsTermsOfSales - The Cur row of the table
//  Cancel - Boolean - Cancel
//
Procedure CheckWhetherEndOfStringPeriodIsValid(Val MaxDate, Val TableName, Val TablePresentation, Val CurrentEndDate, CurrentTableRow, Cancel)
	
	If Not CurrentTableRow.InitialString
	   And CurrentEndDate <= MaxDate Then
		
		Template = NStr("vi = 'Tại dòng %1 danh sách ""%2"" ngày kết thúc không thể nhỏ hơn hoặc bằng %3 - ngày cuối kỳ ghi nhận tính toán';
						|ru = 'В строке %1 списка ""%2"" дата окончания не может быть меньше или равна %3 - даты окончания периода зарегистрированного начисления';
						|en = 'In line %1 of the ""%2"" list, the end date cannot be less than or equal to %3 - the end date of the registered accrual period'; fa = 'In line %1 of the ""%2"" list, the end date cannot be less than or equal to %3 - the end date of the registered accrual period';
						|it = 'В строке %1 списка ""%2"" дата окончания не может быть меньше или равна %3 - даты окончания периода зарегистрированного начисления';
						|pl = 'In line %1 of the ""%2"" list, the end date cannot be less than or equal to %3 - the end date of the registered accrual period';
						|tr = '""%2"" listesinin %1 satırında, başlangıç tarihi şunlardan erken veya şunlara eşit olamaz:%3- Kayıtlı tahakkuk döneminin bitiş tarihi'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			Template,
			String(CurrentTableRow.LineNumber),
			TablePresentation,
			Format(MaxDate, "DLF=D;"));
		
		Field = CommonClientServer.PathToTabularSection(
			TableName, CurrentTableRow.LineNumber, "ValidTo");
		
		Common.MessageToUser(MessageText,, Field, "Object", Cancel);
		
	EndIf;
	
EndProcedure

// Checking whether there is a change in the expiration date of the retro bonus in the source line during the registered accrual, when the expiration date of the retro bonus before the change was less than the maximum end date of the registered accrual period.
// 
// Parameters:
//  MaxDate - Date - Maximum end date of the registered accrual period
//  TableName - String - table name
//  TablePresentation - String - Table Presentation
//  CurrentEndDate - Date - End date in the original line
//  CurrentTableRow - DocumentTabularSectionRow.ConditionsOfVendorRebates.CustomerCounterparties, DocumentTabularSectionRow.ConditionsOfVendorRebates.ClientsCounterpartiesTIN, DocumentTabularSectionRow.ConditionsOfVendorRebates.Goods, DocumentTabularSectionRow.ConditionsOfVendorRebates.Vendors, DocumentTabularSectionRow.ConditionsOfCustomerRebates.Counterparties, DocumentTabularSectionRow.ConditionsOfCustomerRebates.CounterpartiesTIN, DocumentTabularSectionRow.ConditionsOfCustomerRebates.Goods, DocumentTabularSectionRow.ConditionsOfCustomerRebates.ContractsTermsOfSales - The Cur row of the table
//  Cancel - Boolean - Cancel
//
Procedure CheckWhetherEndOfPeriodOfSourceStringHasChanged(Val MaxDate, Val TableName, Val TablePresentation, Val CurrentEndDate, CurrentTableRow, Cancel)
	
	If CurrentTableRow.InitialString
	   And Not CurrentTableRow.Canceled
	   And CurrentTableRow.EndDateBeforeChange <> Date(1, 1, 1)
	   And CurrentTableRow.EndDateBeforeChange < MaxDate
	   And CurrentEndDate <> CurrentTableRow.EndDateBeforeChange Then
		
		Template = NStr("vi = 'Tại dòng %1 danh sách ""%2"" không thể thay đổi ngày kết thúc, bởi vì đã ghi nhận tính toán vào kỳ hiệu lực điều kiện';
						|ru = 'В строке %1 списка ""%2"" дата окончания не может быть изменена, так как в период действия условия были зарегистрированы начисления';
						|en = 'In line %1 of the ""%2"" list, the end date cannot be changed as accruals were registered during the condition validity period'; fa = 'In line %1 of the ""%2"" list, the end date cannot be changed as accruals were registered during the condition validity period';
						|it = 'В строке %1 списка ""%2"" дата окончания не может быть изменена, так как в период действия условия были зарегистрированы начисления';
						|pl = 'In line %1 of the ""%2"" list, the end date cannot be changed as accruals were registered during the condition validity period';
						|tr = '""%2"" listesinin %1 satırında, tahakkukların şartlar döneminde kaydedilmesinden dolayı bitiş tarihi değiştirilemez'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			Template,
			String(CurrentTableRow.LineNumber),
			TablePresentation);
		
		Field = CommonClientServer.PathToTabularSection(
			TableName, CurrentTableRow.LineNumber, "ValidTo");
		
		Common.MessageToUser(MessageText,, Field, "Object", Cancel);
		
	EndIf;
	
EndProcedure

// Checking the expiration date of the retro bonus in the source line in relation to the maximum expiration date of the registered accrual period, when the expiration date of the retro bonus before the change was greater than or equal to the maximum expiration date of the registered accrual period.
// 
// Parameters:
//  MaxDate - Date - Maximum end date of the registered accrual period
//  TableName - String - table name
//  TablePresentation - String - Table Presentation
//  CurrentEndDate - Date - End date in the original line
//  CurrentTableRow - DocumentTabularSectionRow.ConditionsOfVendorRebates.CustomerCounterparties, DocumentTabularSectionRow.ConditionsOfVendorRebates.ClientsCounterpartiesTIN, DocumentTabularSectionRow.ConditionsOfVendorRebates.Goods, DocumentTabularSectionRow.ConditionsOfVendorRebates.Vendors, DocumentTabularSectionRow.ConditionsOfCustomerRebates.Counterparties, DocumentTabularSectionRow.ConditionsOfCustomerRebates.CounterpartiesTIN, DocumentTabularSectionRow.ConditionsOfCustomerRebates.Goods, DocumentTabularSectionRow.ConditionsOfCustomerRebates.ContractsTermsOfSales - The Cur row of the table
//  Cancel - Boolean - Cancel
//
Procedure CheckValidityOfChangingEndOfPeriodOfOriginalLine(Val MaxDate, Val TableName, Val TablePresentation, Val CurrentEndDate, CurrentTableRow, Cancel)
	
	If CurrentTableRow.InitialString
	   And Not CurrentTableRow.Canceled
	   And CurrentTableRow.EndDateBeforeChange >= MaxDate
	   And CurrentEndDate < MaxDate Then
		
		Template = NStr("vi = 'Tại dòng %1 danh sách ""%2"" ngày kết thúc không thể nhỏ hơn %3 - ngày cuối kỳ ghi nhận tính toán';
						|ru = 'В строке %1 списка ""%2"" дата окончания не может быть меньше %3 - даты окончания периода зарегистрированного начисления';
						|en = 'In line %1 of the ""%2"" list, the end date cannot be less than %3 - the end date of the registered accrual period'; fa = 'In line %1 of the ""%2"" list, the end date cannot be less than %3 - the end date of the registered accrual period';
						|it = 'В строке %1 списка ""%2"" дата окончания не может быть меньше %3 - даты окончания периода зарегистрированного начисления';
						|pl = 'In line %1 of the ""%2"" list, the end date cannot be less than %3 - the end date of the registered accrual period';
						|tr = '""%2"" listesinin %1 satırında, başlangıç tarihi aşağıdakilerden küçük veya eşit olamaz:%3- Kayıtlı tahakkuk döneminin bitiş tarihi'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			Template,
			String(CurrentTableRow.LineNumber),
			TablePresentation,
			Format(MaxDate, "DLF=D;"));
		Field = CommonClientServer.PathToTabularSection(
			TableName, CurrentTableRow.LineNumber, "ValidTo");
		Common.MessageToUser(MessageText,, Field, "Object", Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// Parameters:
//  DataTable - DocumentTabularSection.ConditionsOfCustomerRebates.Goods
//                - DocumentTabularSection.ConditionsOfVendorRebates.Goods
//  CheckParameters - See ParametersForCheckingPeriodsByKeys
// 
// Returns:
//  Structure - Goods Period Data By Key:
// * IntersectionsOfPeriods - QueryResultSelection:
//	** FirstRow - Number -
// 	** Products - CatalogRef.Products -
// 	** Characteristic - CatalogRef.ItemsCharacteristics -
// * DuplicatesOfPercentagePlan - QueryResultSelection:
//	** FirstRow - Number -
// 	** Products - CatalogRef.Products -
// 	** Characteristic - CatalogRef.ItemsCharacteristics -
// * DuplicatesByRanges - QueryResultSelection:
//	** FirstRow - Number -
// 	** Products - CatalogRef.Products -
// 	** Characteristic - CatalogRef.ItemsCharacteristics -
// 	** CountPlan - Number -
// 
Function GoodsPeriodDataByKey(DataTable, CheckParameters);
	
	ThisIsProgressiveScale = False;
	ThisIsScaleByRanges = False;
	ThisIsScaleCalculation = False;
	
	If CheckParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Count Then
		
		ThisIsProgressiveScale = (CheckParameters.CalculationScaleType = 0);
		ThisIsScaleByRanges = (CheckParameters.CalculationScaleType = 1);
		ThisIsScaleCalculation =
			(ThisIsProgressiveScale
			 Or ThisIsScaleByRanges);
		
	EndIf;
	
	Query = New Query;
	QueryText =
	"SELECT
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.Products AS Products,
	|	DataTable.Characteristic AS Characteristic,
	|	DataTable.CountPlan AS CountPlan,
	|	DataTable.Percent AS Percent,
	|	CASE
	|		WHEN DataTable.ValidOnDate = DATETIME(1, 1, 1)
	|			THEN &ValidOnDate
	|		ELSE DataTable.ValidOnDate
	|	END AS ValidOnDate,
	|	CASE
	|		WHEN DataTable.ValidTo = DATETIME(1, 1, 1)
	|			THEN &ValidTo
	|		ELSE DataTable.ValidTo
	|	END AS ValidTo
	|INTO DataTable
	|FROM
	|	&PreparedData AS DataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataTable.Products AS Products,
	|	DataTable.Characteristic AS Characteristic,
	|	MIN(DataTable.LineNumber) AS FirstRow
	|FROM
	|	DataTable AS DataTable
	|		INNER JOIN DataTable AS MirrorDataTable
	|		ON DataTable.LineNumber <> MirrorDataTable.LineNumber
	|		AND DataTable.Products = MirrorDataTable.Products
	|		AND DataTable.Characteristic = MirrorDataTable.Characteristic
	|		AND (DataTable.ValidOnDate BETWEEN MirrorDataTable.ValidOnDate AND MirrorDataTable.ValidTo
	|		OR DataTable.ValidTo
	|			BETWEEN MirrorDataTable.ValidOnDate AND MirrorDataTable.ValidTo)
	|WHERE
	|	NOT &ThisIsScaleCalculation
	|GROUP BY
	|	DataTable.Products,
	|	DataTable.Characteristic
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	MIN(TableOfGoods.LineNumber)
	|FROM
	|	DataTable AS TableOfGoods
	|		INNER JOIN DataTable AS GoodsTableMirror
	|		ON TableOfGoods.LineNumber <> GoodsTableMirror.LineNumber
	|		AND TableOfGoods.Products = GoodsTableMirror.Products
	|		AND TableOfGoods.Characteristic = GoodsTableMirror.Characteristic
	|		AND (TableOfGoods.ValidOnDate
	|			BETWEEN GoodsTableMirror.ValidOnDate AND GoodsTableMirror.ValidTo
	|		OR TableOfGoods.ValidTo
	|			BETWEEN GoodsTableMirror.ValidOnDate AND GoodsTableMirror.ValidTo
	|		OR &WholePeriod)
	|		AND (TableOfGoods.ValidOnDate <> GoodsTableMirror.ValidOnDate
	|		OR TableOfGoods.ValidTo <> GoodsTableMirror.ValidTo)
	|WHERE
	|	&ThisIsProgressiveScale
	|GROUP BY
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DataTable.Products AS Products,
	|	DataTable.Characteristic AS Characteristic,
	|	MIN(DataTable.LineNumber) AS FirstRow
	|FROM
	|	DataTable AS DataTable
	|		INNER JOIN DataTable AS MirrorDataTable
	|		ON DataTable.LineNumber <> MirrorDataTable.LineNumber
	|		AND DataTable.Products = MirrorDataTable.Products
	|		AND DataTable.Characteristic = MirrorDataTable.Characteristic
	|		AND (DataTable.ValidOnDate BETWEEN MirrorDataTable.ValidOnDate AND MirrorDataTable.ValidTo
	|		OR DataTable.ValidTo
	|			BETWEEN MirrorDataTable.ValidOnDate AND MirrorDataTable.ValidTo
	|		OR &WholePeriod)
	|		AND (DataTable.CountPlan = MirrorDataTable.CountPlan
	|		OR DataTable.Percent = MirrorDataTable.Percent)
	|WHERE
	|	&ThisIsProgressiveScale
	|GROUP BY
	|	DataTable.Products,
	|	DataTable.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DataTable.Products AS Products,
	|	DataTable.Characteristic AS Characteristic,
	|	DataTable.CountPlan AS CountPlan,
	|	MIN(DataTable.LineNumber) AS FirstRow
	|FROM
	|	DataTable AS DataTable
	|		INNER JOIN DataTable AS MirrorDataTable
	|		ON DataTable.LineNumber <> MirrorDataTable.LineNumber
	|		AND DataTable.Products = MirrorDataTable.Products
	|		AND DataTable.Characteristic = MirrorDataTable.Characteristic
	|		AND DataTable.CountPlan = MirrorDataTable.CountPlan
	|WHERE
	|	&ThisIsScaleByRanges
	|GROUP BY
	|	DataTable.Products,
	|	DataTable.Characteristic,
	|	DataTable.CountPlan";
	
	Query.Text = QueryText;
	
	FilterParameters = New Structure("Canceled", False);
	UnloadingColumns = "LineNumber, Products, Characteristic, CountPlan, Percent, ValidOnDate, ValidTo";
	PreparedData= DataTable.Unload(FilterParameters, UnloadingColumns);
	Query.SetParameter("PreparedData", PreparedData);
	
	Query.SetParameter("ValidOnDate", CheckParameters.ValidOnDate);
	Query.SetParameter("ValidTo", CheckParameters.ValidTo);
	
	Query.SetParameter("ThisIsProgressiveScale", ThisIsProgressiveScale);
	Query.SetParameter("ThisIsScaleByRanges", ThisIsScaleByRanges);
	Query.SetParameter("ThisIsScaleCalculation", ThisIsScaleCalculation);
	
	WholePeriod = (ThisIsProgressiveScale
				  And CheckParameters.ConditionFrequency = Enums.RebatesFrequencies.WholePeriod);
	Query.SetParameter("WholePeriod", WholePeriod);
	
	QueryResult = Query.ExecuteBatch(); // QueryResult
	TotalResults = QueryResult.UBound();
	
	SelectionOfPeriodIntersections = QueryResult[TotalResults - 2].Select();
	SelectionOfDuplicatesOfPercentagePlan = QueryResult[TotalResults - 1].Select();
	SelectionOfDuplicatesOfRangeScale = QueryResult[TotalResults].Select();
	
	Result = New Structure;
	Result.Insert("IntersectionsOfPeriods", SelectionOfPeriodIntersections);
	Result.Insert("DuplicatesOfPercentagePlan", SelectionOfDuplicatesOfPercentagePlan);
	Result.Insert("DuplicatesByRanges", SelectionOfDuplicatesOfRangeScale);
	
	Return Result;
	
EndFunction

// Parameters:
//  DataTable - DocumentTabularSection.ConditionsOfCustomerRebates.ProductProperties_
//                - DocumentTabularSection.ConditionsOfVendorRebates.ProductProperties_
//  CheckParameters - See ParametersForCheckingPeriodsByKeys
// 
// Returns:
//  Structure - Goods Period Data By Key:
// * IntersectionsOfPeriods - QueryResultSelection:
//	** FirstRow - Number -
// 	** PropertyValue - DefinedType.RebateItemPropertyTypes
// * DuplicatesOfPercentagePlan - QueryResultSelection:
//	** FirstRow - Number -
// 	** PropertyValue - DefinedType.RebateItemPropertyTypes
// * DuplicatesByRanges - QueryResultSelection:
//	** FirstRow - Number -
// 	** PropertyValue - DefinedType.RebateItemPropertyTypes
// 	** CountPlan - Number -
// 
Function DataForPeriodsOfItemPropertiesByKey(DataTable, CheckParameters);
	
	ThisIsProgressiveScale = False;
	ThisIsScaleByRanges = False;
	ThisIsScaleCalculation = False;
	
	If CheckParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Count Then
		
		ThisIsProgressiveScale = (CheckParameters.CalculationScaleType = 0);
		ThisIsScaleByRanges = (CheckParameters.CalculationScaleType = 1);
		ThisIsScaleCalculation =
			(ThisIsProgressiveScale
			 Or ThisIsScaleByRanges);
		
	EndIf;
	
	Query = New Query;
	QueryText =
	"SELECT
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.PropertyValue AS PropertyValue,
	|	DataTable.CountPlan AS CountPlan,
	|	DataTable.Percent AS Percent,
	|	CASE
	|		WHEN DataTable.ValidOnDate = DATETIME(1, 1, 1)
	|			THEN &ValidOnDate
	|		ELSE DataTable.ValidOnDate
	|	END AS ValidOnDate,
	|	CASE
	|		WHEN DataTable.ValidTo = DATETIME(1, 1, 1)
	|			THEN &ValidTo
	|		ELSE DataTable.ValidTo
	|	END AS ValidTo
	|INTO DataTable
	|FROM
	|	&PreparedData AS DataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataTable.PropertyValue AS PropertyValue,
	|	MIN(DataTable.LineNumber) AS FirstRow
	|FROM
	|	DataTable AS DataTable
	|		INNER JOIN DataTable AS MirrorDataTable
	|		ON DataTable.LineNumber <> MirrorDataTable.LineNumber
	|		AND DataTable.PropertyValue = MirrorDataTable.PropertyValue
	|		AND (DataTable.ValidOnDate BETWEEN MirrorDataTable.ValidOnDate AND MirrorDataTable.ValidTo
	|		OR DataTable.ValidTo
	|			BETWEEN MirrorDataTable.ValidOnDate AND MirrorDataTable.ValidTo)
	|WHERE
	|	NOT &ThisIsScaleCalculation
	|GROUP BY
	|	DataTable.PropertyValue
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.PropertyValue,
	|	MIN(TableOfGoods.LineNumber)
	|FROM
	|	DataTable AS TableOfGoods
	|		INNER JOIN DataTable AS GoodsTableMirror
	|		ON TableOfGoods.LineNumber <> GoodsTableMirror.LineNumber
	|		AND TableOfGoods.PropertyValue = GoodsTableMirror.PropertyValue
	|		AND (TableOfGoods.ValidOnDate
	|			BETWEEN GoodsTableMirror.ValidOnDate AND GoodsTableMirror.ValidTo
	|		OR TableOfGoods.ValidTo
	|			BETWEEN GoodsTableMirror.ValidOnDate AND GoodsTableMirror.ValidTo
	|		OR &WholePeriod)
	|		AND (TableOfGoods.ValidOnDate <> GoodsTableMirror.ValidOnDate
	|		OR TableOfGoods.ValidTo <> GoodsTableMirror.ValidTo)
	|WHERE
	|	&ThisIsProgressiveScale
	|GROUP BY
	|	TableOfGoods.PropertyValue
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DataTable.PropertyValue AS PropertyValue,
	|	MIN(DataTable.LineNumber) AS FirstRow
	|FROM
	|	DataTable AS DataTable
	|		INNER JOIN DataTable AS MirrorDataTable
	|		ON DataTable.LineNumber <> MirrorDataTable.LineNumber
	|		AND DataTable.PropertyValue = MirrorDataTable.PropertyValue
	|		AND (DataTable.ValidOnDate BETWEEN MirrorDataTable.ValidOnDate AND MirrorDataTable.ValidTo
	|		OR DataTable.ValidTo
	|			BETWEEN MirrorDataTable.ValidOnDate AND MirrorDataTable.ValidTo
	|		OR &WholePeriod)
	|		AND (DataTable.CountPlan = MirrorDataTable.CountPlan
	|		OR DataTable.Percent = MirrorDataTable.Percent)
	|WHERE
	|	&ThisIsProgressiveScale
	|GROUP BY
	|	DataTable.PropertyValue
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DataTable.PropertyValue AS PropertyValue,
	|	DataTable.CountPlan AS CountPlan,
	|	MIN(DataTable.LineNumber) AS FirstRow
	|FROM
	|	DataTable AS DataTable
	|		INNER JOIN DataTable AS MirrorDataTable
	|		ON DataTable.LineNumber <> MirrorDataTable.LineNumber
	|		AND DataTable.PropertyValue = MirrorDataTable.PropertyValue
	|		AND DataTable.CountPlan = MirrorDataTable.CountPlan
	|WHERE
	|	&ThisIsScaleByRanges
	|GROUP BY
	|	DataTable.PropertyValue,
	|	DataTable.CountPlan";
	
	Query.Text = QueryText;
	
	FilterParameters = New Structure("Canceled", False);
	UnloadingColumns = "LineNumber, PropertyValue, CountPlan, Percent, ValidOnDate, ValidTo";
	PreparedData = DataTable.Unload(FilterParameters, UnloadingColumns);
	Query.SetParameter("PreparedData", PreparedData);
	
	Query.SetParameter("ValidOnDate", CheckParameters.ValidOnDate);
	Query.SetParameter("ValidTo", CheckParameters.ValidTo);
	
	Query.SetParameter("ThisIsProgressiveScale", ThisIsProgressiveScale);
	Query.SetParameter("ThisIsScaleByRanges", ThisIsScaleByRanges);
	Query.SetParameter("ThisIsScaleCalculation", ThisIsScaleCalculation);
	
	WholePeriod = (ThisIsProgressiveScale
				  And CheckParameters.ConditionFrequency = Enums.RebatesFrequencies.WholePeriod);
	Query.SetParameter("WholePeriod", WholePeriod);
	
	QueryResult = Query.ExecuteBatch(); // QueryResult
	TotalResults = QueryResult.UBound();
	
	SelectionOfPeriodIntersections = QueryResult[TotalResults - 2].Select();
	SelectionOfDuplicatesOfPercentagePlan = QueryResult[TotalResults - 1].Select();
	SelectionOfDuplicatesOfRangeScale = QueryResult[TotalResults].Select();
	
	Result = New Structure;
	Result.Insert("IntersectionsOfPeriods", SelectionOfPeriodIntersections);
	Result.Insert("DuplicatesOfPercentagePlan", SelectionOfDuplicatesOfPercentagePlan);
	Result.Insert("DuplicatesByRanges", SelectionOfDuplicatesOfRangeScale);
	
	Return Result;
	
EndFunction

// Parameters:
//  GoodsTableBeingProcessed - FormDataCollection, DocumentTabularSection.ConditionsOfCustomerRebates.Goods, DocumentTabularSection.ConditionsOfVendorRebates.Goods - Goods Table Being Processed
//  TempTableManager - TempTablesManager
// 
// Returns:
//  QueryResultSelection:
//  * LineNumber - Number
//  * Products - CatalogRef.Products
//  * Characteristic - CatalogRef.ItemsCharacteristics
//  * ItemVariantsAreUsed - Boolean
//
Function SelectionOfGoodsWithoutBonusInterest(GoodsTableBeingProcessed, TempTableManager)
	
	CreateTemporaryGoodsTableToCheckRanges(GoodsTableBeingProcessed, TempTableManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	QueryText =
	"SELECT
	|	MIN(TTProducts_1.LineNumber) AS LineNumber,
	|	TTProducts_1.Products AS Products,
	|	TTProducts_1.Characteristic AS Characteristic
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|WHERE
	|NOT TTProducts_1.Canceled
	|
	|GROUP BY
	|	TTProducts_1.Characteristic,
	|	TTProducts_1.Products
	|
	|HAVING
	|	MIN(CASE
	|			WHEN TTProducts_1.Percent = 0
	|				THEN 1
	|			ELSE 0
	|		END) > 0
	|
	|ORDER BY
	|	LineNumber";
	
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	
	Return Selection;
	
EndFunction

// Parameters:
//  ProcessedTable - FormDataCollection, DocumentTabularSection.ConditionsOfCustomerRebates.ProductProperties_, DocumentTabularSection.ConditionsOfVendorRebates.ProductProperties_ - table being processed
//  TempTableManager - TempTablesManager
// 
// Returns:
//  QueryResultSelection:
//  * LineNumber - Number
//  * PropertyValue - DefinedType.RebateItemPropertyTypes
//
Function SelectionOfItemPropertiesWithoutBonusInterest(ProcessedTable, TempTableManager)
	
	CreateTemporaryPropertyTableForCheckingRanges(ProcessedTable, TempTableManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	QueryText =
	"SELECT
	|	MIN(TTNomenclatureProperties.LineNumber) AS LineNumber,
	|	TTNomenclatureProperties.PropertyValue AS PropertyValue
	|FROM
	|	TTNomenclatureProperties AS TTNomenclatureProperties
	|WHERE
	|NOT TTNomenclatureProperties.Canceled
	|
	|GROUP BY
	|	TTNomenclatureProperties.PropertyValue
	|
	|HAVING
	|	MIN(CASE
	|			WHEN TTNomenclatureProperties.Percent = 0
	|				THEN 1
	|			ELSE 0
	|		END) > 0
	|
	|ORDER BY
	|	LineNumber";
	
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	
	Return Selection;
	
EndFunction

// Parameters:
//  VerificationObject - See CheckIndicationOfEmptyCharacteristicValues
//   KindAttributes - Structure:
//  	* GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods
// 
// Returns:
//  QueryResultSelection:
//	* LineNumber - Number -
//	* Products - CatalogRef.Products
//
Function SelectionOfEmptyAndFilledCharacteristics(VerificationObject, KindAttributes)
	
	FilterOfProducts_ = VerificationObject.FilterOfProducts_;
	ConditionFrequency = VerificationObject.ConditionFrequency;
	ValidOnDate = VerificationObject.ValidOnDate;
	ValidTo = VerificationObject.ValidTo;
	
	RowFilter = New Structure;
	RowFilter.Insert("Canceled", False);
	
	Query = New Query;
	
	If FilterOfProducts_ = Enums.RebatesLists.ExceptForSelectedOnes
	 Or (ConditionFrequency = Enums.RebatesFrequencies.WholePeriod
	      And KindAttributes.GoodsIndicator =  Enums.TargetSalesIndicatorsOfRebatesByGoods.Count) Then
		
		QueryText = QueryTextForEmptyAndFilledInCharacteristics();
		Columns = "LineNumber, Products, Characteristic";
		
	Else
		
		QueryText = QueryTextForEmptyAndFilledInCharacteristicsTakingIntoAccountPeriod();
		Columns = "LineNumber, Products, Characteristic, ValidOnDate, ValidTo";
		Query.SetParameter("ValidOnDate", ValidOnDate);
		Query.SetParameter("ValidTo", ValidTo);
		
	EndIf;
	
	CheckTable = VerificationObject.Goods.Unload(RowFilter, Columns);
	Query.SetParameter("CheckTable", CheckTable);
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	
	Return Selection;
	
EndFunction

Function QueryTextForEmptyAndFilledInCharacteristicsTakingIntoAccountPeriod()
	
	QueryText =
	"SELECT
	|	CheckTable.LineNumber AS LineNumber,
	|	CheckTable.Products AS Products,
	|	CheckTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN CheckTable.ValidOnDate = DATETIME(1, 1, 1)
	|			THEN &ValidOnDate
	|		ELSE CheckTable.ValidOnDate
	|	END AS ValidOnDate,
	|	CASE
	|		WHEN CheckTable.ValidTo = DATETIME(1, 1, 1)
	|			THEN &ValidTo
	|		ELSE CheckTable.ValidTo
	|	END AS ValidTo
	|INTO CheckTable
	|FROM
	|	&CheckTable AS CheckTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CheckTable.LineNumber AS LineNumber,
	|	CheckTable.Products AS Products,
	|	CheckTable.ValidOnDate AS ValidOnDate,
	|	CheckTable.ValidTo AS ValidTo
	|INTO VT_RowsWithoutCharacteristics
	|FROM
	|	CheckTable AS CheckTable
	|WHERE
	|	CheckTable.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	VT_RowsWithoutCharacteristics.LineNumber AS LineNumber,
	|	VT_RowsWithoutCharacteristics.Products AS Products
	|FROM
	|	VT_RowsWithoutCharacteristics AS VT_RowsWithoutCharacteristics
	|		INNER JOIN CheckTable AS CheckTable
	|		ON VT_RowsWithoutCharacteristics.Products = CheckTable.Products
	|			AND VT_RowsWithoutCharacteristics.ValidOnDate <= CheckTable.ValidTo
	|			AND VT_RowsWithoutCharacteristics.ValidTo >= CheckTable.ValidOnDate
	|			AND (CheckTable.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef))";
	
	Return QueryText;
	
EndFunction

Function QueryTextForEmptyAndFilledInCharacteristics()
	
	QueryText =
	"SELECT
	|	CheckTable.LineNumber AS LineNumber,
	|	CheckTable.Products AS Products,
	|	CheckTable.Characteristic AS Characteristic
	|INTO CheckTable
	|FROM
	|	&CheckTable AS CheckTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(CheckTable.LineNumber) AS LineNumber,
	|	CheckTable.Products AS Products
	|FROM
	|	CheckTable AS CheckTable
	|GROUP BY
	|	Products,
	|	CheckTable.Products
	|HAVING
	|	COUNT(DISTINCT CASE
	|		WHEN Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|			THEN 0
	|		ELSE 1
	|	END) > 1";
	
	Return QueryText;
	
EndFunction

// Returns:
//  ValueTreeRow, FormDataTreeItem - See ProcessingOfFormulas.NewLineOfOperandTree
//
Function GetTreeOfOperandsOfNomenclature()
	
	SetPrivilegedMode(True);
	
	OperandsTree = ProcessingOfFormulas.GetEmptyOperandTree();
	
	RootRowOfTree = ProcessingOfFormulas.NewLineOfOperandTree(OperandsTree);
	RootRowOfTree.Id = "Products";
	RootRowOfTree.Presentation = NStr("vi = 'Mặt hàng';
										|ru = 'Номенклатура';
										|en = 'Item'; fa = 'قلم';
										|it = 'Item';
										|pl = 'Item';
										|tr = 'Öğe'");
	RootRowOfTree.ValueType = New TypeDescription("CatalogRef.Products");
	RootRowOfTree.OperandSelectionAllowed = False;
	RootRowOfTree.IncludedInID = False;
	RootRowOfTree.ExpandToAttributes = True;
	
	// Formation of the second layer of operands. The composition of additional details (from a set of properties) is redefined.
	// 1. Description of additional restrictions on the details layer and additional details.
	SweepRestrictions = ProcessingOfFormulas.LimitationsOfOperandSweep();
	SweepRestrictions.RecursivelyExpandLayoutSchemeOperands = False;
	ProcessingOfFormulas.ExpandOperandString(RootRowOfTree, SweepRestrictions);
	
	Return RootRowOfTree;
	
EndFunction

Function IsItemAttribute(Val IDOfAttribute)
	
	Result = True;
	ObjectMetadata = Metadata.Catalogs.Products;
	
	If Not Common.IsStandardAttribute(ObjectMetadata.StandardAttributes, IDOfAttribute) Then
		
		Result = Common.HasObjectAttribute(IDOfAttribute, ObjectMetadata);
		
	EndIf;
	
	Return Result;
	
EndFunction

Function IsAdditionalAttributeOfItem(Val IDOfAttribute)
	
	Result = ItemAttributeData();
	IdOfAdditionalAttributeOfProperty = ProcessingOfFormulas.PropertiesCharacteristics(IDOfAttribute).Id;
	
	If Not GetFunctionalOption("UseAdditionalAttributesAndInfo") Then
		
		Result.AdditionalAttribute = True;
		Result.Title = IdOfAdditionalAttributeOfProperty;
		Return Result;
		
	EndIf;
	
	Result.AvailableByFunctionalOptions = True;
	SharedSet = PropertyManager.PropertiesSetByName("Catalog_Products_Overall");
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	QueryText =
	"SELECT
	|	AdditionalAttributesAndInfo.Ref AS Property,
	|	AdditionalAttributesAndInfo.ValueType AS ValueType,
	|	AdditionalAttributesAndInfo.DeletionMark AS DeletionMark
	|INTO TT_AdditionalAttributes
	|FROM
	|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS AdditionalAttributesAndInfo
	|WHERE
	|	&ExpressionIDForFormulas = &AdditionalAttributeIds
	|	AND NOT AdditionalAttributesAndInfo.IsAdditionalInfo
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ItemKinds.PropertiesSet AS PropertiesSet
	|INTO VT_SetsOfItemProperties
	|FROM
	|	Catalog.ItemKinds AS ItemKinds
	|WHERE
	|	NOT ItemKinds.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	&SharedSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_AdditionalAttributes.Property AS Property,
	|	TT_AdditionalAttributes.ValueType AS ValueType,
	|	SetsOfAdditionalAttributes.Ref AS Ref
	|INTO TT_AdditionalAttributeSets
	|FROM
	|	TT_AdditionalAttributes AS TT_AdditionalAttributes
	|		INNER JOIN Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS SetsOfAdditionalAttributes
	|			INNER JOIN Catalog.AdditionalAttributesAndInfoSets AS AdditionalAttributesAndInfoSets
	|			ON SetsOfAdditionalAttributes.Ref = AdditionalAttributesAndInfoSets.Ref
	|				AND (AdditionalAttributesAndInfoSets.Used)
	|		ON TT_AdditionalAttributes.Property = SetsOfAdditionalAttributes.Property
	|			AND (NOT SetsOfAdditionalAttributes.DeletionMark)
	|WHERE
	|	NOT AdditionalAttributesAndInfoSets.IsFolder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TT_AdditionalAttributeSets.Property AS Property,
	|	TT_AdditionalAttributeSets.ValueType AS ValueType
	|FROM
	|	TT_AdditionalAttributeSets AS TT_AdditionalAttributeSets
	|		INNER JOIN VT_SetsOfItemProperties AS VT_SetsOfItemProperties
	|		ON TT_AdditionalAttributeSets.Ref = VT_SetsOfItemProperties.PropertiesSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TT_AdditionalAttributeSets.Ref AS Ref,
	|	TT_AdditionalAttributeSets.Property AS Property,
	|	TT_AdditionalAttributeSets.ValueType AS ValueType
	|FROM
	|	TT_AdditionalAttributeSets AS TT_AdditionalAttributeSets
	|		LEFT JOIN VT_SetsOfItemProperties AS VT_SetsOfItemProperties
	|		ON TT_AdditionalAttributeSets.Ref = VT_SetsOfItemProperties.PropertiesSet
	|WHERE
	|	VT_SetsOfItemProperties.PropertiesSet IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_AdditionalAttributes.Property AS Property,
	|	TT_AdditionalAttributes.ValueType AS ValueType
	|FROM
	|	TT_AdditionalAttributes AS TT_AdditionalAttributes
	|		LEFT JOIN Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS SetsOfAdditionalAttributes
	|		ON TT_AdditionalAttributes.Property = SetsOfAdditionalAttributes.Property
	|WHERE
	|	SetsOfAdditionalAttributes.Property IS NULL
	|	AND NOT TT_AdditionalAttributes.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_AdditionalAttributes.Property AS Property,
	|	TT_AdditionalAttributes.ValueType AS ValueType
	|FROM
	|	TT_AdditionalAttributes AS TT_AdditionalAttributes
	|WHERE
	|	TT_AdditionalAttributes.DeletionMark";
	
	ExpressionIDForFormulas = StringFunctionsClientServer.SubstituteParametersToString(
		"AdditionalAttributesAndInfo.%1",
		ProcessingOfFormulas.IdFieldForAdditionalBankingDetails());
	
	QueryText = StrReplace(QueryText, "&ExpressionIDForFormulas", ExpressionIDForFormulas);
	
	Query.SetParameter("SharedSet", SharedSet);
	Query.SetParameter("AdditionalAttributeIds", IdOfAdditionalAttributeOfProperty);
	Query.Text = QueryText;
	
	QueryResult = Query.ExecuteBatch();
	NumberOfResults = QueryResult.UBound();
	AttributeBelongsToSetOfItems = QueryResult[NumberOfResults - 3];
	AttributeBelongsToDifferentSet = QueryResult[NumberOfResults - 2];
	AttributeDoesNotBelongToSet = QueryResult[NumberOfResults - 1];
	AttributeHasBeenMarkedForDeletion = QueryResult[NumberOfResults];
	
	AttributeData = New Structure;
	AttributeData.Insert("Is_Attribute", False);
	AttributeData.Insert("BelongsToAnotherSet", False);
	AttributeData.Insert("DoesNotBelongToSet", False);
	AttributeData.Insert("DeletionMark", False);
	AttributeData.Insert("AttributeNotFound", False);
	
	If Not AttributeBelongsToSetOfItems.IsEmpty() Then
		
		AttributeData.Is_Attribute = True;
		Selection = AttributeBelongsToSetOfItems.Select();
		FillInDetailsOfAdditionalAttributesOfItem(Result, AttributeData, Selection);
		
	ElsIf Not AttributeBelongsToDifferentSet.IsEmpty() Then
		
		AttributeData.BelongsToAnotherSet = True;
		Selection = AttributeBelongsToDifferentSet.Select();
		FillInDetailsOfAdditionalAttributesOfItem(Result, AttributeData, Selection);
		
	ElsIf Not AttributeDoesNotBelongToSet.IsEmpty() Then
		
		AttributeData.DoesNotBelongToSet = True;
		Selection = AttributeDoesNotBelongToSet.Select();
		FillInDetailsOfAdditionalAttributesOfItem(Result, AttributeData, Selection);
		
	ElsIf Not AttributeHasBeenMarkedForDeletion.IsEmpty() Then
		
		AttributeData.DeletionMark = True;
		Selection = AttributeHasBeenMarkedForDeletion.Select();
		FillInDetailsOfAdditionalAttributesOfItem(Result, AttributeData, Selection);
		
	Else
		
		AttributeData.AttributeNotFound = True;
		FillInDetailsOfAdditionalAttributesOfItem(Result, AttributeData);
		Result.Title = IdOfAdditionalAttributeOfProperty;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Fill in the item Attributes.
// 
// Parameters:
//  Result - See ItemAttributeData
//  AttributeData - Structure:
//   * Is_Attribute - Boolean
//   * BelongsToAnotherSet - Boolean
//   * DoesNotBelongToSet - Boolean
//   * DeletionMark - Boolean
//   * AttributeNotFound - Boolean
//  Selection - QueryResultSelection:
//   * ValueType - TypeDescription
//   * Property - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo
//
Procedure FillInDetailsOfAdditionalAttributesOfItem(Result, AttributeData, Selection = Undefined)
	
	Result.AdditionalAttribute = True;
	FillPropertyValues(Result, AttributeData);
	AllowedValueType = False;
	
	If Selection <> Undefined Then
		
		Selection.Next();
		ValueType = Selection.ValueType; // TypeDescription
		Property = Selection.Property; // ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo
		Result.Property = Property;
		Result.ValueType = ValueType;
		Result.Title = Common.ObjectAttributeValue(Property, "Title",, CurrentLanguage().LanguageCode);
		AllowedValueType = AllowedValueTypeForItemProperty(ValueType);
		
	EndIf;
	
	Result.AllowedValueType = AllowedValueType;
	Result.AllowedToUse = (Result.Is_Attribute
										And Not Result.DeletionMark
										And Not Result.AttributeNotFound
										And AllowedValueType);
	
EndProcedure

// Returns:
//  Structure - Item Attribute Data:
// * Is_Attribute - Boolean - 
// * Property - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo - 
// * ValueType - TypeDescription - 
// * Title - String - 
// * AvailableByFunctionalOptions - Boolean - 
// * AdditionalAttribute - Boolean - 
// * DeletionMark - Boolean - 
// * AttributeNotFound - Boolean
// * AllowedValueType - Boolean
// * AllowedToUse - Boolean
// * BelongsToAnotherSet - Boolean
// * DoesNotBelongToSet - Boolean
// 
Function ItemAttributeData()
	
	AttributeData = New Structure;
	AttributeData.Insert("Is_Attribute", False);
	AttributeData.Insert("Property", ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.EmptyRef());
	AttributeData.Insert("ValueType", New TypeDescription());
	AttributeData.Insert("Title", "");
	AttributeData.Insert("AvailableByFunctionalOptions", False);
	AttributeData.Insert("AdditionalAttribute", False);
	AttributeData.Insert("DeletionMark", False);
	AttributeData.Insert("AttributeNotFound", False);
	AttributeData.Insert("AllowedValueType", False);
	AttributeData.Insert("AllowedToUse", False);
	AttributeData.Insert("BelongsToAnotherSet", False);
	AttributeData.Insert("DoesNotBelongToSet", False);
	
	Return AttributeData;
	
EndFunction

// Parameters:
//  ProhibitionReason - Structure:
//   * ShortDescription - String
//   * DetailedDescription - String
//   * MessageText - String
//  CheckResult - See ItemAttributeData
//  RebateKindIsUsed - Boolean
// 
Procedure ReasonForBanForAttribute(ProhibitionReason, Val CheckResult, Val RebateKindIsUsed)
	
	ShortDescription = "";
	DetailedDescription = "";
	MessageText = "";
	
	If CheckResult.AttributeNotFound Then
		
		If RebateKindIsUsed Then
			
			DetailedDescription = NStr("vi = 'Mục tin đã bị xóa hoặc đổi tên. Các chứng từ đã nhập trước đó không hợp lệ. Dạng thưởng lũy kế không được dùng trong các chứng từ. Cần chọn thuộc tính khác có cùng kiểu giá trị với thuộc tính trước đó. Hãy liên hệ với người quản trị hệ thống.';
										|ru = 'Реквизит был удален или переименован. Ранее введенные документы являются некорректными. Вид ретро-бонуса не может использоваться в документах. Необходимо выбрать другое свойство с тем же типом значения, что и у предыдущего. Обратитесь к администратору системы.';
										|en = 'The attribute is deleted or renamed. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with the same value type as the previous one. Contact the system administrator.'; fa = 'The attribute is deleted or renamed. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with the same value type as the previous one. Contact the system administrator.';
										|it = 'The attribute is deleted or renamed. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with the same value type as the previous one. Contact the system administrator.';
										|pl = 'The attribute is deleted or renamed. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with the same value type as the previous one. Contact the system administrator.';
										|tr = 'Öznitelik silindi veya yeniden adlandırıldı. Daha önce girilen belgeler hatalı. Retro bonusunun türü belgelerde kullanılamaz. Öncekiyle aynı değer türüne sahip başka bir özellik seçmelisiniz. Sistem yöneticisiyle iletişime geçin.'");
			
		Else
			
			DetailedDescription = NStr("vi = 'Mục tin đã bị xóa hoặc đổi tên. Dạng thưởng lũy kế không được dùng trong các chứng từ. Cần chọn thuộc tính khác.';
										|ru = 'Реквизит был удален или переименован. Вид ретро-бонуса не может использоваться в документах. Необходимо выбрать другое свойство.';
										|en = 'The attribute is deleted or renamed. Cannot use the rebate kind in documents. Select a different property.'; fa = 'The attribute is deleted or renamed. Cannot use the rebate kind in documents. Select a different property.';
										|it = 'The attribute is deleted or renamed. Cannot use the rebate kind in documents. Select a different property.';
										|pl = 'The attribute is deleted or renamed. Cannot use the rebate kind in documents. Select a different property.';
										|tr = 'Öznitelik silindi veya yeniden adlandırıldı. Retro bonusunun türü belgelerde kullanılamaz. Başka bir özellik seçmelisiniz.'");
			
		EndIf;
		
		TemplateShortDescription = NStr("vi = 'Không tìm thấy thuộc tính (<a href=""%1"">chi tiết</a>)';
										|ru = 'Свойство не найдено (<a href=""%1"">подробнее</a>)';
										|en = 'The property is not found (<a href=""%1"">details</a>)'; fa = 'The property is not found (<a href=""%1"">details</a>)';
										|it = 'The property is not found (<a href=""%1"">details</a>)';
										|pl = 'The property is not found (<a href=""%1"">details</a>)';
										|tr = 'Özellik bulunamadı (<a href=""%1"">ayrıntılar</a>)'");
		MessageTemplate = NStr("vi = 'Không tìm thấy thuộc tính mặt hàng ""%1"" (đã bị xóa hoặc đổi tên).';
								|ru = 'Свойство номенклатуры ""%1"" не найдено (было удалено или переименовано).';
								|en = 'The ""%1"" item property is not found (it was deleted or renamed).'; fa = 'The ""%1"" item property is not found (it was deleted or renamed).';
								|it = 'The ""%1"" item property is not found (it was deleted or renamed).';
								|pl = 'The ""%1"" item property is not found (it was deleted or renamed).';
								|tr = '""%1"" öğe özelliği bulunamadı (silindi veya yeniden adlandırıldı).'");
		
	ElsIf Not CheckResult.AvailableByFunctionalOptions
	   And CheckResult.Is_Attribute Then
		
		If RebateKindIsUsed Then
			
			DetailedDescription = NStr("vi = 'Đã tắt tùy chọn chức năng cho phép sử dụng thuộc tính này. Các chứng từ đã nhập trước đó không hợp lệ. Dạng thưởng lũy kế không thể được sử dụng trong các chứng từ. Cần bật tính năng sử dụng thuộc tính trong tùy chỉnh hệ thống hoặc chọn một thuộc tính khác có cùng kiểu giá trị với thuộc tính trước đó. Vui lòng liên hệ với người quản trị hệ thống để được hỗ trợ.';
										|ru = 'Отключена функциональная опция, разрешающая использование свойства. Ранее введенные документы являются некорректными. Вид ретро-бонуса не может использоваться в документах. Необходимо включить использование свойства в настройках системы или выбрать другое свойство с тем же типом значения, что и у предыдущего. Обратитесь к администратору системы.';
										|en = 'The functional option that allows the use of the property is disabled. Previously entered documents are invalid. You cannot use the rebate kind in documents. Enable the use of the property in the system settings, or select another property with the same value type as the previous one. Contact your system administrator.'; fa = 'The functional option that allows the use of the property is disabled. Previously entered documents are invalid. You cannot use the rebate kind in documents. Enable the use of the property in the system settings, or select another property with the same value type as the previous one. Contact your system administrator.';
										|it = 'The functional option that allows the use of the property is disabled. Previously entered documents are invalid. You cannot use the rebate kind in documents. Enable the use of the property in the system settings, or select another property with the same value type as the previous one. Contact your system administrator.';
										|pl = 'The functional option that allows the use of the property is disabled. Previously entered documents are invalid. You cannot use the rebate kind in documents. Enable the use of the property in the system settings, or select another property with the same value type as the previous one. Contact your system administrator.';
										|tr = 'Özelliğin kullanımına izin veren işlevsellik seçeneği devre dışı bırakıldı. Daha önce girilen belgeler hatalı. Retro bonusunun türü belgelerde kullanılamaz. Özelliğin kullanımını sistem ayarlarından etkinleştirmeli veya öncekiyle aynı değer türüne sahip başka bir özellik seçmelisiniz. Sistem yöneticisiyle iletişime geçin.'");
			
		Else
			
			DetailedDescription = NStr("vi = 'Đã tắt tùy chọn chức năng cho phép sử dụng thuộc tính này. Dạng thưởng lũy kế không thể được sử dụng trong các chứng từ. Cần chọn thuộc tính khác.';
										|ru = 'Отключена функциональная опция, разрешающая использование свойства. Вид ретро-бонуса не может использоваться в документах. Необходимо выбрать другое свойство.';
										|en = 'The functional option that allows the use of the property is disabled. You cannot use the rebate kind in documents. Select another property.'; fa = 'The functional option that allows the use of the property is disabled. You cannot use the rebate kind in documents. Select another property.';
										|it = 'The functional option that allows the use of the property is disabled. You cannot use the rebate kind in documents. Select another property.';
										|pl = 'The functional option that allows the use of the property is disabled. You cannot use the rebate kind in documents. Select another property.';
										|tr = 'Özelliğin kullanımına izin veren işlevsellik seçeneği devre dışı bırakıldı. Retro bonusun türü belgelerde kullanılamaz. Başka bir özellik seçmelisiniz.'");
			
		EndIf;
		
		TemplateShortDescription = NStr("vi = 'Thuộc tính không hợp lệ (<a href=""%1"">chi tiết</a>)';
										|ru = 'Свойство недоступно (<a href=""%1"">подробнее</a>)';
										|en = 'The property is unavailable (<a href=""%1"">details</a>)'; fa = 'The property is unavailable (<a href=""%1"">details</a>)';
										|it = 'The property is unavailable (<a href=""%1"">details</a>)';
										|pl = 'The property is unavailable (<a href=""%1"">details</a>)';
										|tr = 'Özellik mevcut değil (<a href=""%1"">ayrıntılar</a>)'");
		MessageTemplate = NStr("vi = 'Đã tắt tùy chọn chức năng cho phép sử dụng thuộc tính ""%1"".';
								|ru = 'Отключена функциональная опция, разрешающая использование свойства ""%1"".';
								|en = 'The functional option that allows using the ""%1"" property is disabled.'; fa = 'The functional option that allows using the ""%1"" property is disabled.';
								|it = 'The functional option that allows using the ""%1"" property is disabled.';
								|pl = 'The functional option that allows using the ""%1"" property is disabled.';
								|tr = '""%1"" özelliğinin kullanımına izin veren işlevsel opsiyon devre dışı bırakıldı.'");
		
	ElsIf Not CheckResult.AllowedValueType
	   And CheckResult.Is_Attribute Then
		
		If RebateKindIsUsed Then
			
			DetailedDescription = NStr("vi = 'Mục tin có kiểu bị cấm. Các chứng từ đã nhập trước đó không hợp lệ. Dạng thưởng lũy kế không thể được dùng trong các chứng từ. Cần chọn thiết bị khác có kiểu hợp lệ. Vui lòng liên hệ với người quản trị hệ thống.';
										|ru = 'Реквизит имеет запрещенный тип. Ранее введенные документы являются некорректными. Вид ретро-бонуса не может использоваться в документах. Необходимо выбрать другое свойство с допустимым типом. Обратитесь к администратору системы.';
										|en = 'The attribute has a prohibited type. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with a valid type. Contact the system administrator.'; fa = 'The attribute has a prohibited type. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with a valid type. Contact the system administrator.';
										|it = 'The attribute has a prohibited type. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with a valid type. Contact the system administrator.';
										|pl = 'The attribute has a prohibited type. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with a valid type. Contact the system administrator.';
										|tr = 'Öznitelikte yasaklanan tip mevcut. Daha önce girilen belgeler hatalı. Retro bonusunun türü belgelerde kullanılamaz. Geçerli bir tipe sahip başka bir özellik seçmelisiniz. Sistem yöneticisiyle iletişime geçin.'");
			
		Else
			
			DetailedDescription = NStr("vi = 'Mục tin có kiểu bị cấm. Dạng thưởng lũy kế không thể được dùng trong các chứng từ. Cần chọn thuộc tính khác có kiểu hợp lệ.';
										|ru = 'Реквизит имеет запрещенный тип. Вид ретро-бонуса не может использоваться в документах. Необходимо выбрать другое свойство с допустимым типом.';
										|en = 'The attribute has a prohibited type. Cannot use the rebate kind in documents. Select another property with a valid type.'; fa = 'The attribute has a prohibited type. Cannot use the rebate kind in documents. Select another property with a valid type.';
										|it = 'The attribute has a prohibited type. Cannot use the rebate kind in documents. Select another property with a valid type.';
										|pl = 'The attribute has a prohibited type. Cannot use the rebate kind in documents. Select another property with a valid type.';
										|tr = 'Öznitelikte yasaklanan tip mevcut. Retro bonusunun türü belgelerde kullanılamaz. Geçerli bir tipe sahip başka bir özellik seçmelisiniz.'");
			
		EndIf;
		
		TemplateShortDescription = NStr("vi = 'Thuộc tính có kiểu không hợp lệ (<a href=""%1"">chi tiết</a>)';
										|ru = 'Свойство имеет недопустимый тип (<a href=""%1"">подробнее</a>)';
										|en = 'The property has an invalid type (<a href=""%1"">details</a>)'; fa = 'The property has an invalid type (<a href=""%1"">details</a>)';
										|it = 'The property has an invalid type (<a href=""%1"">details</a>)';
										|pl = 'The property has an invalid type (<a href=""%1"">details</a>)';
										|tr = 'Özellik geçersiz tipe sahiptir (<a href=""%1"">ayrıntılar</a>)'");
		MessageTemplate = NStr("vi = 'Thuộc tính mặt hàng ""%1"" có kiểu không hợp lệ và không thể được dùng trong tùy chỉnh dạng thưởng lũy kế.';
								|ru = 'Свойство номенклатуры ""%1"" имеет недопустимый тип и не может использоваться в настройках видов ретро-бонусов.';
								|en = 'The ""%1"" item property has an invalid type and cannot be used in rebate kind settings.'; fa = 'The ""%1"" item property has an invalid type and cannot be used in rebate kind settings.';
								|it = 'The ""%1"" item property has an invalid type and cannot be used in rebate kind settings.';
								|pl = 'The ""%1"" item property has an invalid type and cannot be used in rebate kind settings.';
								|tr = '""%1"" öğe özelliği geçersiz tipe sahiptir ve retro bonusu türlerinin ayarlarında kullanılamaz.'");
		
	Else
		
		If RebateKindIsUsed Then
			
			DetailedDescription = NStr("vi = 'Không tìm thấy mục tin. Các chứng từ đã nhập trước đó không hợp lệ. Dạng thưởng lũy kế không được dùng trong các chứng từ. Cần chọn thuộc tính khác có cùng kiểu giá trị với thuộc tính trước đó. Hãy liên hệ với người quản trị hệ thống.';
										|ru = 'Реквизит не найден. Ранее введенные документы являются некорректными. Вид ретро-бонуса не может использоваться в документах. Необходимо выбрать другое свойство с тем же типом значения, что и у предыдущего. Обратитесь к администратору системы.';
										|en = 'The attribute is not found. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with the same value type as the previous one. Contact the system administrator.'; fa = 'The attribute is not found. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with the same value type as the previous one. Contact the system administrator.';
										|it = 'The attribute is not found. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with the same value type as the previous one. Contact the system administrator.';
										|pl = 'The attribute is not found. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with the same value type as the previous one. Contact the system administrator.';
										|tr = 'Öznitelik bulunamadı. Daha önce girilen belgeler hatalı. Retro bonusunun türü belgelerde kullanılamaz. Öncekiyle aynı değer türüne sahip başka bir özellik seçmelisiniz. Sistem yöneticisiyle iletişime geçin.'");
			
		Else
			
			DetailedDescription = NStr("vi = 'Không tìm thấy mục tin. Dạng thưởng lũy kế không được dùng trong các chứng từ. Cần chọn thuộc tính khác.';
										|ru = 'Реквизит не найден. Вид ретро-бонуса не может использоваться в документах. Необходимо выбрать другое свойство.';
										|en = 'The attribute is not found. Cannot use the rebate kind in documents. Select a different property.'; fa = 'The attribute is not found. Cannot use the rebate kind in documents. Select a different property.';
										|it = 'The attribute is not found. Cannot use the rebate kind in documents. Select a different property.';
										|pl = 'The attribute is not found. Cannot use the rebate kind in documents. Select a different property.';
										|tr = 'Öznitelik bulunamadı. Retro bonusunun türü belgelerde kullanılamaz. Başka bir özellik seçmelisiniz.'");
			
		EndIf;
		
		TemplateShortDescription = NStr("vi = 'Không tìm thấy thuộc tính (<a href=""%1"">chi tiết</a>)';
										|ru = 'Свойство не найдено (<a href=""%1"">подробнее</a>)';
										|en = 'The property is not found (<a href=""%1"">details</a>)'; fa = 'The property is not found (<a href=""%1"">details</a>)';
										|it = 'The property is not found (<a href=""%1"">details</a>)';
										|pl = 'The property is not found (<a href=""%1"">details</a>)';
										|tr = 'Özellik bulunamadı (<a href=""%1"">ayrıntılar</a>)'");
		MessageTemplate = NStr("vi = 'Không tìm thấy thuộc tính mặt hàng ""%1"" (đã bị xóa hoặc đổi tên).';
								|ru = 'Свойство номенклатуры ""%1"" не найдено (было удалено или переименовано).';
								|en = 'The ""%1"" item property is not found (it was deleted or renamed).'; fa = 'The ""%1"" item property is not found (it was deleted or renamed).';
								|it = 'The ""%1"" item property is not found (it was deleted or renamed).';
								|pl = 'The ""%1"" item property is not found (it was deleted or renamed).';
								|tr = '""%1"" öğe özelliği bulunamadı (silindi veya yeniden adlandırıldı).'");
		
	EndIf;
	
	ShowDetailedDescription = "ShowDetailedDescription";
	ShortDescription = StringFunctionsClientServer.SubstituteParametersToString(
			TemplateShortDescription,
			ShowDetailedDescription);
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate,
			CheckResult.Title);
	
	ProhibitionReason.ShortDescription = ShortDescription;
	ProhibitionReason.DetailedDescription = DetailedDescription;
	ProhibitionReason.MessageText = MessageText;
	
EndProcedure

// Parameters:
//  ProhibitionReason - Structure:
//   * ShortDescription - String
//   * DetailedDescription - String
//   * MessageText - String
//  CheckResult - See ItemAttributeData
//  RebateKindIsUsed - Boolean
// 
Procedure ReasonForBanForAdditionalAttributes(ProhibitionReason, Val CheckResult, Val RebateKindIsUsed)
	
	ShortDescription = "";
	DetailedDescription = "";
	MessageText = "";
	
	If Not CheckResult.AvailableByFunctionalOptions Then
			
		If RebateKindIsUsed Then
			
			DetailedDescription = NStr("vi = 'Đã chọn mục tin (thuộc tính) bổ sung, đồng thời tắt sử dụng thuộc tính. Các chứng từ đã nhập trước đó không hợp lệ. Dạng thưởng lũy kế không thể được dùng trong các chứng từ. Cần bật sử dụng thuộc tính trong các tùy chỉnh hệ thống hoặc chọn thuộc tính khác có cùng kiểu giá trị với thuộc tính trước đó. Vui lòng liên hệ với người quản trị hệ thống.';
										|ru = 'Выбран дополнительный реквизит (свойство), при этом отключено использование свойств. Ранее введенные документы являются некорректными. Вид ретро-бонуса не может использоваться в документах. Необходимо включить использование свойств в настройках системы или выбрать другое свойство с тем же типом значения, что и у предыдущего. Обратитесь к администратору системы.';
										|en = 'The additional attribute (property) is selected, while properties are disabled. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Enable properties in the system settings or select another property with the same value type as the previous one. Contact the system administrator.'; fa = 'The additional attribute (property) is selected, while properties are disabled. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Enable properties in the system settings or select another property with the same value type as the previous one. Contact the system administrator.';
										|it = 'The additional attribute (property) is selected, while properties are disabled. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Enable properties in the system settings or select another property with the same value type as the previous one. Contact the system administrator.';
										|pl = 'The additional attribute (property) is selected, while properties are disabled. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Enable properties in the system settings or select another property with the same value type as the previous one. Contact the system administrator.';
										|tr = 'Ek öznitelik (özellik) seçildi, ancak özelliklerin kullanımı devre dışı bırakıldı. Daha önce girilen belgeler hatalı. Retro bonusunun türü belgelerde kullanılamaz. Özelliklerin kullanımını sistem ayarlarından etkinleştirmeli veya öncekiyle aynı değer türüne sahip başka bir özellik seçmelisiniz. Sistem yöneticisiyle iletişime geçin.'");
			
		Else
			
			DetailedDescription = NStr("vi = 'Đã chọn mục tin (thuộc tính) bổ sung, đồng thời tắt sử dụng thuộc tính. Dạng thưởng lũy kế không thể được sử dụng trong các chứng từ. Cần chọn thuộc tính khác.';
										|ru = 'Выбран дополнительный реквизит (свойство), при этом отключено использование свойств. Вид ретро-бонуса не может использоваться в документах. Необходимо выбрать другое свойство.';
										|en = 'The additional attribute (property) is selected, while properties are disabled. Cannot use the rebate kind in documents. Select a different property.'; fa = 'The additional attribute (property) is selected, while properties are disabled. Cannot use the rebate kind in documents. Select a different property.';
										|it = 'The additional attribute (property) is selected, while properties are disabled. Cannot use the rebate kind in documents. Select a different property.';
										|pl = 'The additional attribute (property) is selected, while properties are disabled. Cannot use the rebate kind in documents. Select a different property.';
										|tr = 'Ek öznitelik (özellik) seçildi, ancak özelliklerin kullanımı devre dışı bırakıldı. Retro bonusun türü belgelerde kullanılamaz. Başka bir özellik seçmelisiniz.'");
			
		EndIf;
		
		TemplateShortDescription = NStr("vi = 'Đã tắt sử dụng thuộc tính (<a href=""%1"">chi tiết</a>)';
										|ru = 'Отключено использование свойств (<a href=""%1"">подробнее</a>)';
										|en = 'Properties are disabled (<a href=""%1"">details</a>)'; fa = 'Properties are disabled (<a href=""%1"">details</a>)';
										|it = 'Properties are disabled (<a href=""%1"">details</a>)';
										|pl = 'Properties are disabled (<a href=""%1"">details</a>)';
										|tr = 'Özelliklerin kullanımı devre dışı bırakıldı (<a href=""%1"">ayrıntılar</a>)'");
		MessageTemplate = NStr("vi = 'Đã chọn mục tin bổ sung ""%1"" đồng thời tắt sử dụng thuộc tính.';
								|ru = 'Выбран дополнительный реквизит ""%1"" при этом отключено использование свойств.';
								|en = 'The ""%1"" additional attribute is selected, while properties are disabled.'; fa = 'The ""%1"" additional attribute is selected, while properties are disabled.';
								|it = 'The ""%1"" additional attribute is selected, while properties are disabled.';
								|pl = 'The ""%1"" additional attribute is selected, while properties are disabled.';
								|tr = 'Ek ""%1"" özniteliği seçildi, ancak özelliklerin kullanımı devre dışı bırakıldı.'");
		
	ElsIf CheckResult.DoesNotBelongToSet
	  Or CheckResult.BelongsToAnotherSet Then
		
		If RebateKindIsUsed Then
			
			DetailedDescription = NStr("vi = 'Mục tin (thuộc tính) bổ sung không còn được sử dụng. Nếu xóa mục tin, thì chứng từ thuộc dạng này sẽ không còn hợp lệ. Dạng thưởng lũy kế không thể được dùng trong các chứng từ. Nên khôi phục hiệu lực của mục tin bổ sung hoặc chọn thuộc tính khác dạng thưởng lũy kế. Vui lòng liên hệ với người quản trị hệ thống.';
										|ru = 'Дополнительный реквизит (свойство) больше не используется. В случае удаления реквизита документы по данному виду станут некорректными. Вид ретро-бонуса не может использоваться в документах. Рекомендуем восстановить действие дополнительного реквизита или выбрать другое свойство в виде ретро-бонуса. Обратитесь к администратору системы.';
										|en = 'The additional attribute (property) is no longer used. If you delete the attribute, the documents for this kind will become incorrect. Cannot use the rebate kind in documents. We recommend restoring the additional attribute or choosing another property in the rebate kind. Contact the system administrator.'; fa = 'The additional attribute (property) is no longer used. If you delete the attribute, the documents for this kind will become incorrect. Cannot use the rebate kind in documents. We recommend restoring the additional attribute or choosing another property in the rebate kind. Contact the system administrator.';
										|it = 'The additional attribute (property) is no longer used. If you delete the attribute, the documents for this kind will become incorrect. Cannot use the rebate kind in documents. We recommend restoring the additional attribute or choosing another property in the rebate kind. Contact the system administrator.';
										|pl = 'The additional attribute (property) is no longer used. If you delete the attribute, the documents for this kind will become incorrect. Cannot use the rebate kind in documents. We recommend restoring the additional attribute or choosing another property in the rebate kind. Contact the system administrator.';
										|tr = 'Ek öznitelik (özellik) artık kullanılmıyor. Öznitelik silinirse, bu türdeki belgeler hatalı hale gelir. Retro bonusunun türü belgelerde kullanılamaz. Ek özniteliği geri yüklemenizi veya retro bonusunun türünde başka bir özellik seçmenizi öneririz. Sistem yöneticisiyle iletişime geçin.'");
			
		Else
			
			DetailedDescription = NStr("vi = 'Mục tin (thuộc tính) bổ sung không còn được sử dụng. Dạng thưởng lũy kế không được dùng trong các chứng từ. Cần chọn thiết bị khác.';
										|ru = 'Дополнительный реквизит (свойство) больше не используется. Вид ретро-бонуса не может использоваться в документах. Необходимо выбрать другое свойство.';
										|en = 'The additional attribute (property) is no longer used. Cannot use the rebate kind in documents. Select a different property.'; fa = 'The additional attribute (property) is no longer used. Cannot use the rebate kind in documents. Select a different property.';
										|it = 'The additional attribute (property) is no longer used. Cannot use the rebate kind in documents. Select a different property.';
										|pl = 'The additional attribute (property) is no longer used. Cannot use the rebate kind in documents. Select a different property.';
										|tr = 'Ek öznitelik (özellik) artık kullanılmıyor. Retro bonusunun türü belgelerde kullanılamaz. Başka bir özellik seçmelisiniz.'");
			
		EndIf;
		
		TemplateShortDescription = NStr("vi = 'Thuộc tính không được sử dụng (<a href=""%1"">chi tiết</a>)';
										|ru = 'Свойство не используется (<a href=""%1"">подробнее</a>)';
										|en = 'The property is not used (<a href=""%1"">details</a>)'; fa = 'The property is not used (<a href=""%1"">details</a>)';
										|it = 'The property is not used (<a href=""%1"">details</a>)';
										|pl = 'The property is not used (<a href=""%1"">details</a>)';
										|tr = 'Özellik kullanılmıyor (<a href=""%1"">ayrıntılar</a>)'");
		MessageTemplate = NStr("vi = 'Mục tin bổ sung ""%1"" không còn được sử dụng.';
								|ru = 'Дополнительный реквизит ""%1"" больше не используется.';
								|en = 'The ""%1"" additional attribute is no longer used.'; fa = 'The ""%1"" additional attribute is no longer used.';
								|it = 'The ""%1"" additional attribute is no longer used.';
								|pl = 'The ""%1"" additional attribute is no longer used.';
								|tr = 'Ek ""%1"" özniteliği artık kullanılmıyor.'");
		
	ElsIf CheckResult.DeletionMark Then
		
		If RebateKindIsUsed Then
			
			DetailedDescription = NStr("vi = 'Mục tin (thuộc tính) bổ sung đã bị đặt dấu xóa. Nếu xóa mục tin, thì chứng từ thuộc dạng này sẽ không còn hợp lệ. Dạng thưởng lũy kế không thể được sử dụng trong các chứng từ. Nên khôi phục hiệu lực của mục tin bổ sung hoặc chọn thuộc tính khác dạng thưởng lũy kế. Vui lòng liên hệ với người quản trị hệ thống.';
										|ru = 'Дополнительный реквизит (свойство) помечен на удаление. В случае удаления реквизита документы по данному виду станут некорректными. Вид ретро-бонуса не может использоваться в документах. Рекомендуем восстановить действие дополнительного реквизита или выбрать другое свойство в виде ретро-бонуса. Обратитесь к администратору системы.';
										|en = 'The additional attribute (property) is marked for deletion. If you delete the attribute, the documents for this kind will become incorrect. Cannot use the rebate kind in documents. We recommend restoring the additional attribute or choosing another property in the rebate kind. Contact the system administrator.'; fa = 'The additional attribute (property) is marked for deletion. If you delete the attribute, the documents for this kind will become incorrect. Cannot use the rebate kind in documents. We recommend restoring the additional attribute or choosing another property in the rebate kind. Contact the system administrator.';
										|it = 'The additional attribute (property) is marked for deletion. If you delete the attribute, the documents for this kind will become incorrect. Cannot use the rebate kind in documents. We recommend restoring the additional attribute or choosing another property in the rebate kind. Contact the system administrator.';
										|pl = 'The additional attribute (property) is marked for deletion. If you delete the attribute, the documents for this kind will become incorrect. Cannot use the rebate kind in documents. We recommend restoring the additional attribute or choosing another property in the rebate kind. Contact the system administrator.';
										|tr = 'Ek öznitelik (özellik) silinmek üzere işaretlendi. Öznitelik silinirse, bu türdeki belgeler hatalı hale gelir. Retro bonusunun türü belgelerde kullanılamaz. Ek özniteliği geri yüklemenizi veya retro bonusunun türünde başka bir özellik seçmenizi öneririz. Sistem yöneticisiyle iletişime geçin.'");
			
		Else
			
			DetailedDescription = NStr("vi = 'Mục tin (thuộc tính) bổ sung đã bị đặt dấu xóa. Dạng thưởng lũy kế không được dùng trong các chứng từ. Cần chọn thuộc tính khác.';
										|ru = 'Дополнительный реквизит (свойство) помечен на удаление. Вид ретро-бонуса не может использоваться в документах. Необходимо выбрать другое свойство.';
										|en = 'The additional attribute (property) is marked for deletion. Cannot use the rebate kind in documents. Select a different property.'; fa = 'The additional attribute (property) is marked for deletion. Cannot use the rebate kind in documents. Select a different property.';
										|it = 'The additional attribute (property) is marked for deletion. Cannot use the rebate kind in documents. Select a different property.';
										|pl = 'The additional attribute (property) is marked for deletion. Cannot use the rebate kind in documents. Select a different property.';
										|tr = 'Ek öznitelik (özellik) silinmek üzere işaretlendi. Retro bonusunun türü belgelerde kullanılamaz. Başka bir özellik seçmelisiniz.'");
			
		EndIf;
		
		TemplateShortDescription = NStr("vi = 'Thuộc tính đã bị đặt dấu xóa (<a href=""%1"">chi tiết</a>)';
										|ru = 'Свойство помечено на удаление (<a href=""%1"">подробнее</a>)';
										|en = 'The property is marked for deletion (<a href=""%1"">details</a>)'; fa = 'The property is marked for deletion (<a href=""%1"">details</a>)';
										|it = 'The property is marked for deletion (<a href=""%1"">details</a>)';
										|pl = 'The property is marked for deletion (<a href=""%1"">details</a>)';
										|tr = 'Özellik silinmek üzere işaretlendi (<a href=""%1"">ayrıntılar</a>)'");
		MessageTemplate = NStr("vi = 'Mục tin bổ sung ""%1"" đã bị đặt dấu xóa.';
								|ru = 'Дополнительный реквизит ""%1"" помечен на удаление.';
								|en = 'The ""%1"" additional attribute is marked for deletion.'; fa = 'The ""%1"" additional attribute is marked for deletion.';
								|it = 'The ""%1"" additional attribute is marked for deletion.';
								|pl = 'The ""%1"" additional attribute is marked for deletion.';
								|tr = 'Ek ""%1"" özniteliği silinmek üzere işaretlendi.'");
		
	ElsIf CheckResult.AttributeNotFound Then
		
		If RebateKindIsUsed Then
			
			DetailedDescription = NStr("vi = 'Mục tin (thuộc tính) bổ sung đã bị xóa hoặc đổi ID. Các chứng từ đã nhập trước đó không hợp lệ. Dạng thưởng lũy kế không được dùng trong các chứng từ. Cần chọn thuộc tính khác có cùng kiểu giá trị với thuộc tính trước đó. Hãy liên hệ với người quản trị hệ thống.';
										|ru = 'Дополнительный реквизит (свойство) был удален или у него был изменен идентификатор. Ранее введенные документы являются некорректными. Вид ретро-бонуса не может использоваться в документах. Необходимо выбрать другое свойство с тем же типом значения, что и у предыдущего. Обратитесь к администратору системы.';
										|en = 'The additional attribute (property) is deleted, or its ID is changed. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with the same value type as the previous one. Contact the system administrator.'; fa = 'The additional attribute (property) is deleted, or its ID is changed. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with the same value type as the previous one. Contact the system administrator.';
										|it = 'The additional attribute (property) is deleted, or its ID is changed. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with the same value type as the previous one. Contact the system administrator.';
										|pl = 'The additional attribute (property) is deleted, or its ID is changed. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with the same value type as the previous one. Contact the system administrator.';
										|tr = 'Ek öznitelik (özellik) silindi veya tanımlayıcısı değiştirildi. Daha önce girilen belgeler hatalı. Retro bonusunun türü belgelerde kullanılamaz. Öncekiyle aynı değer türüne sahip başka bir özellik seçmelisiniz. Sistem yöneticisiyle iletişime geçin.'");
			
		Else
			
			DetailedDescription = NStr("vi = 'Mục tin (thuộc tính) bổ sung đã bị xóa hoặc thay đổi ID. Dạng thưởng lũy kế không được dùng trong các chứng từ. Cần chọn thuộc tính khác.';
										|ru = 'Дополнительный реквизит (свойство) был удален или у него был изменен идентификатор. Вид ретро-бонуса не может использоваться в документах. Необходимо выбрать другое свойство.';
										|en = 'The additional attribute (property) is deleted, or its ID is changed. Cannot use the rebate kind in documents. Select a different property.'; fa = 'The additional attribute (property) is deleted, or its ID is changed. Cannot use the rebate kind in documents. Select a different property.';
										|it = 'The additional attribute (property) is deleted, or its ID is changed. Cannot use the rebate kind in documents. Select a different property.';
										|pl = 'The additional attribute (property) is deleted, or its ID is changed. Cannot use the rebate kind in documents. Select a different property.';
										|tr = 'Ek öznitelik (özellik) silindi veya tanımlayıcısı değiştirildi. Retro bonusunun türü belgelerde kullanılamaz. Başka bir özellik seçmelisiniz.'");
			
		EndIf;
		
		TemplateShortDescription = NStr("vi = 'Không tìm thấy thuộc tính (<a href=""%1"">chi tiết</a>)';
										|ru = 'Свойство не найдено (<a href=""%1"">подробнее</a>)';
										|en = 'The property is not found (<a href=""%1"">details</a>)'; fa = 'The property is not found (<a href=""%1"">details</a>)';
										|it = 'The property is not found (<a href=""%1"">details</a>)';
										|pl = 'The property is not found (<a href=""%1"">details</a>)';
										|tr = 'Özellik bulunamadı (<a href=""%1"">ayrıntılar</a>)'");
		MessageTemplate = NStr("vi = 'Không tìm thấy mục tin bổ sung theo ID ""%1"" (mục tin đã bị xóa hoặc đổi ID).';
								|ru = 'Дополнительный реквизит не найден по идентификатору ""%1"" (реквизит был удален или у него изменен идентификатор).';
								|en = 'The additional attribute is not found by ID ""%1"" (the attribute is deleted, or its ID is changed).'; fa = 'The additional attribute is not found by ID ""%1"" (the attribute is deleted, or its ID is changed).';
								|it = 'The additional attribute is not found by ID ""%1"" (the attribute is deleted, or its ID is changed).';
								|pl = 'The additional attribute is not found by ID ""%1"" (the attribute is deleted, or its ID is changed).';
								|tr = '""%1"" tanımlayıcısı kapsamında ek öznitelik bulunamadı (öznitelik silindi veya tanımlayıcısı değiştirildi).'");
		
	ElsIf Not CheckResult.AllowedValueType
	   And CheckResult.Is_Attribute Then
		
		If RebateKindIsUsed Then
			
			DetailedDescription = NStr("vi = 'Mục tin (thuộc tính) bổ sung có kiểu bị cấm. Các chứng từ đã nhập trước đó không hợp lệ. Dạng thưởng lũy kế không thể được dùng trong các chứng từ. Cần thay đổi kiểu thuộc tính hoặc chọn thuộc tính khác có kiểu hợp lệ. Hãy liên hệ với người quản trị hệ thống.';
										|ru = 'Дополнительный реквизит (свойство) имеет запрещенный тип. Ранее введенные документы являются некорректными. Вид ретро-бонуса не может использоваться в документах. Необходимо изменить тип свойства или выбрать другое свойство с допустимым типом. Обратитесь к администратору системы.';
										|en = 'The additional attribute (property) has a prohibited type. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Change the property type or select another property with a valid type. Contact the system administrator.'; fa = 'The additional attribute (property) has a prohibited type. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Change the property type or select another property with a valid type. Contact the system administrator.';
										|it = 'The additional attribute (property) has a prohibited type. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Change the property type or select another property with a valid type. Contact the system administrator.';
										|pl = 'The additional attribute (property) has a prohibited type. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Change the property type or select another property with a valid type. Contact the system administrator.';
										|tr = 'Ek öznitelikte (özellikte) yasaklanan tip mevcut. Daha önce girilen belgeler hatalı. Retro bonusunun türü belgelerde kullanılamaz. Özelliğin tipini değiştirmeniz veya geçerli bir tipe sahip başka bir özellik seçmelisiniz. Sistem yöneticisiyle iletişime geçin.'");
			
		Else
			
			DetailedDescription = NStr("vi = 'Mục tin (thuộc tính) bổ sung có kiểu bị cấm. Dạng thưởng lũy kế không thể được dùng trong các chứng từ. Cần thay đổi kiểu thuộc tính hoặc chọn thuộc tính khác có kiểu hợp lệ.';
										|ru = 'Дополнительный реквизит (свойство) имеет запрещенный тип. Вид ретро-бонуса не может использоваться в документах. Необходимо изменить тип свойства или выбрать другое свойство с допустимым типом.';
										|en = 'The additional attribute (property) has a prohibited type. Cannot use the rebate kind in documents. Change the property type or select another property with a valid type.'; fa = 'The additional attribute (property) has a prohibited type. Cannot use the rebate kind in documents. Change the property type or select another property with a valid type.';
										|it = 'The additional attribute (property) has a prohibited type. Cannot use the rebate kind in documents. Change the property type or select another property with a valid type.';
										|pl = 'The additional attribute (property) has a prohibited type. Cannot use the rebate kind in documents. Change the property type or select another property with a valid type.';
										|tr = 'Ek öznitelikte (özellikte) yasaklanan tip mevcut. Retro bonusunun türü belgelerde kullanılamaz. Özelliğin tipini değiştirmeniz veya geçerli bir tipe sahip başka bir özellik seçmelisiniz.'");
			
		EndIf;
		
		TemplateShortDescription = NStr("vi = 'Thuộc tính có kiểu không hợp lệ (<a href=""%1"">chi tiết</a>)';
										|ru = 'Свойство имеет недопустимый тип (<a href=""%1"">подробнее</a>)';
										|en = 'The property has an invalid type (<a href=""%1"">details</a>)'; fa = 'The property has an invalid type (<a href=""%1"">details</a>)';
										|it = 'The property has an invalid type (<a href=""%1"">details</a>)';
										|pl = 'The property has an invalid type (<a href=""%1"">details</a>)';
										|tr = 'Özellik geçersiz tipe sahiptir (<a href=""%1"">ayrıntılar</a>)'");
		MessageTemplate = NStr("vi = 'Mục tin bổ sung ""%1"" có kiểu không hợp lệ và không thể được dùng trong tùy chỉnh dạng thưởng lũy kế.';
								|ru = 'Дополнительный реквизит ""%1""  имеет недопустимый тип и не может использоваться в настройках видов ретро-бонусов.';
								|en = 'The ""%1"" additional attribute has an invalid type and cannot be used in rebate kind settings.'; fa = 'The ""%1"" additional attribute has an invalid type and cannot be used in rebate kind settings.';
								|it = 'The ""%1"" additional attribute has an invalid type and cannot be used in rebate kind settings.';
								|pl = 'The ""%1"" additional attribute has an invalid type and cannot be used in rebate kind settings.';
								|tr = '""%1"" ek özniteliği geçersiz tipe sahiptir ve retro bonusu türlerinin ayarlarında kullanılamaz.'");
		
	Else
		
		If RebateKindIsUsed Then
			
			DetailedDescription = NStr("vi = 'Không tìm thấy mục tin (thuộc tính) bổ sung. Các chứng từ đã nhập trước đó không hợp lệ. Dạng thưởng lũy kế không được dùng trong các chứng từ. Cần chọn thuộc tính khác có cùng kiểu giá trị với thuộc tính trước đó. Hãy liên hệ với người quản trị hệ thống.';
										|ru = 'Дополнительный реквизит (свойство) не найден. Ранее введенные документы являются некорректными. Вид ретро-бонуса не может использоваться в документах. Необходимо выбрать другое свойство с тем же типом значения, что и у предыдущего. Обратитесь к администратору системы.';
										|en = 'The additional attribute (property) is not found. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with the same value type as the previous one. Contact the system administrator.'; fa = 'The additional attribute (property) is not found. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with the same value type as the previous one. Contact the system administrator.';
										|it = 'The additional attribute (property) is not found. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with the same value type as the previous one. Contact the system administrator.';
										|pl = 'The additional attribute (property) is not found. Previously entered documents are incorrect. Cannot use the rebate kind in documents. Select another property with the same value type as the previous one. Contact the system administrator.';
										|tr = 'Ek öznitelik (özellik) bulunamadı. Daha önce girilen belgeler hatalı. Retro bonusunun türü belgelerde kullanılamaz. Öncekiyle aynı değer türüne sahip başka bir özellik seçmelisiniz. Sistem yöneticisiyle iletişime geçin.'");
			
		Else
			
			DetailedDescription = NStr("vi = 'Không tìm thấy mục tin (thuộc tính) bổ sung. Dạng thưởng lũy kế không được dùng trong các chứng từ. Cần chọn thuộc tính khác.';
										|ru = 'Дополнительный реквизит (свойство) не найден. Вид ретро-бонуса не может использоваться в документах. Необходимо выбрать другое свойство.';
										|en = 'The additional attribute (property) is not found. Cannot use the rebate kind in documents. Select a different property.'; fa = 'The additional attribute (property) is not found. Cannot use the rebate kind in documents. Select a different property.';
										|it = 'The additional attribute (property) is not found. Cannot use the rebate kind in documents. Select a different property.';
										|pl = 'The additional attribute (property) is not found. Cannot use the rebate kind in documents. Select a different property.';
										|tr = 'Ek öznitelik (özellik) bulunamadı. Retro bonusunun türü belgelerde kullanılamaz. Başka bir özellik seçmelisiniz.'");
			
		EndIf;
		
		TemplateShortDescription = NStr("vi = 'Không tìm thấy thuộc tính (<a href=""%1"">chi tiết</a>)';
										|ru = 'Свойство не найдено (<a href=""%1"">подробнее</a>)';
										|en = 'The property is not found (<a href=""%1"">details</a>)'; fa = 'The property is not found (<a href=""%1"">details</a>)';
										|it = 'The property is not found (<a href=""%1"">details</a>)';
										|pl = 'The property is not found (<a href=""%1"">details</a>)';
										|tr = 'Özellik bulunamadı (<a href=""%1"">ayrıntılar</a>)'");
		MessageTemplate = NStr("vi = 'Không tìm thấy mục tin bổ sung theo ID ""%1"" (mục tin đã bị xóa hoặc đổi ID).';
								|ru = 'Дополнительный реквизит не найден по идентификатору ""%1"" (реквизит был удален или у него изменен идентификатор).';
								|en = 'The additional attribute is not found by ID ""%1"" (the attribute is deleted, or its ID is changed).'; fa = 'The additional attribute is not found by ID ""%1"" (the attribute is deleted, or its ID is changed).';
								|it = 'The additional attribute is not found by ID ""%1"" (the attribute is deleted, or its ID is changed).';
								|pl = 'The additional attribute is not found by ID ""%1"" (the attribute is deleted, or its ID is changed).';
								|tr = '""%1"" tanımlayıcısı kapsamında ek öznitelik bulunamadı (öznitelik silindi veya tanımlayıcısı değiştirildi).'");
		
	EndIf;
	
	ShowDetailedDescription = "ShowDetailedDescription";
	ShortDescription = StringFunctionsClientServer.SubstituteParametersToString(
		TemplateShortDescription,
		ShowDetailedDescription);
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate,
			CheckResult.Title);
	
	ProhibitionReason.ShortDescription = ShortDescription;
	ProhibitionReason.DetailedDescription = DetailedDescription;
	ProhibitionReason.MessageText = MessageText;
	
EndProcedure

// Blocking the undo flag in the document correction
//
// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance -
//  FormTable - FormTable - form table
// 
Procedure DesignOfCancellationFlag(ConditionalAppearance, FormTable)
	
	KTCHPath = FormTable.DataPath;
	TSName = FormTable.Name;
	NameCanceled = TSName + "Canceled";
	PathToOriginalString = KTCHPath + ".InitialString";
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameCanceled);
	
	OrGroup = NewFiltersGroup(Item.Filter);
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToOriginalString);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

#Region GoodsByRanges

// Returns:
// 	ValueTable:
// 		* Products - CatalogRef.Products
// 		* Characteristic - CatalogRef.ItemsCharacteristics
// 		* ItemVariantsAreUsed - Boolean
//  
Function NewTableOfGoodsByProcessingRanges()
	
	TypeProducts = New TypeDescription("CatalogRef.Products");
	TypeOfProductCharacteristics = New TypeDescription("CatalogRef.ItemsCharacteristics");
	BooleanType = New TypeDescription("Boolean");
	
	Table_For_Processing = New ValueTable;
	Table_For_Processing.Columns.Add("Products", TypeProducts);
	Table_For_Processing.Columns.Add("Characteristic", TypeOfProductCharacteristics);
	Table_For_Processing.Columns.Add("ItemVariantsAreUsed", BooleanType);
	
	Return Table_For_Processing;
	
EndFunction

// Parameters:
//  GoodsTableBeingProcessed - FormDataCollection, DocumentTabularSection.ConditionsOfCustomerRebates.Goods, DocumentTabularSection.ConditionsOfVendorRebates.Goods - table being processed
//  TempTableManager - TempTablesManager
// 
Procedure CreateTemporaryGoodsTableToCheckRanges(GoodsTableBeingProcessed, TempTableManager)
	
	If TempTableManager.Tables.Find("TTProducts_1") <> Undefined Then
		Return;
	EndIf;
	
	TableData = GoodsTableBeingProcessed.Unload();
	
	RequestForTTGoods = New Query;
	RequestForTTGoods.TempTablesManager = TempTableManager;
	
	If TableData.Columns.Find("ItemVariantsAreUsed") <> Undefined Then
		
		QueryText =
		"SELECT
		|	ProductData_9.LineNumber AS LineNumber,
		|	ProductData_9.Products AS Products,
		|	ProductData_9.Characteristic AS Characteristic,
		|	ProductData_9.ItemVariantsAreUsed AS ItemVariantsAreUsed,
		|	ProductData_9.ValidOnDate AS ValidOnDate,
		|	ProductData_9.ValidTo AS ValidTo,
		|	ProductData_9.CountPlan AS CountPlan,
		|	ProductData_9.BasePrice AS BasePrice,
		|	ProductData_9.Percent AS Percent,
		|	ProductData_9.Canceled AS Canceled
		|INTO TTProducts_1
		|FROM
		|	&GoodsTableBeingProcessed AS ProductData_9";
		
	Else
		
		QueryText =
		"SELECT
		|	ProductData_9.LineNumber AS LineNumber,
		|	ProductData_9.Products AS Products,
		|	ProductData_9.Characteristic AS Characteristic,
		|	ProductData_9.ValidOnDate AS ValidOnDate,
		|	ProductData_9.ValidTo AS ValidTo,
		|	ProductData_9.CountPlan AS CountPlan,
		|	ProductData_9.BasePrice AS BasePrice,
		|	ProductData_9.Percent AS Percent,	
		|	ProductData_9.Canceled AS Canceled
		|INTO TTGoodsIntermediate
		|FROM
		|	&GoodsTableBeingProcessed AS ProductData_9
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTGoodsIntermediate.LineNumber AS LineNumber,
		|	TTGoodsIntermediate.Products AS Products,
		|	TTGoodsIntermediate.Characteristic AS Characteristic,
		|	TTGoodsIntermediate.ValidOnDate AS ValidOnDate,
		|	TTGoodsIntermediate.ValidTo AS ValidTo,
		|	CASE
		|		WHEN CAST(TTGoodsIntermediate.Products AS Catalog.Products).UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind), VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ItemVariantsAreUsed,
		|	TTGoodsIntermediate.CountPlan AS CountPlan,
		|	TTGoodsIntermediate.BasePrice AS BasePrice,
		|	TTGoodsIntermediate.Percent AS Percent,
		|	TTGoodsIntermediate.Canceled AS Canceled
		|INTO TTProducts_1
		|FROM
		|	TTGoodsIntermediate AS TTGoodsIntermediate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTGoodsIntermediate";
		
	EndIf;
	
	RequestForTTGoods.Text = QueryText;
	RequestForTTGoods.SetParameter("GoodsTableBeingProcessed", TableData);
	RequestForTTGoods.Execute();
	
EndProcedure

// Parameters:
//  GoodsTableBeingProcessed - FormDataCollection, DocumentTabularSection.ConditionsOfCustomerRebates.Goods, DocumentTabularSection.ConditionsOfVendorRebates.Goods - Goods Table Being Processed
//  TempTableManager - TempTablesManager
//  SortInDescendingOrder - Boolean
// 
// Returns:
//  QueryResultSelection:
//  * LineNumber - Number
//  * Products - CatalogRef.Products
//  * Characteristic - CatalogRef.ItemsCharacteristics
//  * ItemVariantsAreUsed - Boolean
//
Function SelectionOfGoodsWithoutInitialRange(GoodsTableBeingProcessed, TempTableManager, SortInDescendingOrder = False)
	
	CreateTemporaryGoodsTableToCheckRanges(GoodsTableBeingProcessed, TempTableManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	QueryText =
	"SELECT
	|	MIN(TTProducts_1.LineNumber) AS LineNumber,
	|	TTProducts_1.Products AS Products,
	|	TTProducts_1.Characteristic AS Characteristic,
	|	TTProducts_1.ItemVariantsAreUsed AS ItemVariantsAreUsed
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|WHERE
	|NOT TTProducts_1.Canceled
	|
	|GROUP BY
	|	TTProducts_1.Characteristic,
	|	TTProducts_1.Products,
	|	TTProducts_1.ItemVariantsAreUsed
	|
	|HAVING
	|	MIN(CASE
	|			WHEN TTProducts_1.CountPlan <> 0
	|				THEN 1
	|			ELSE 0
	|		END) > 0
	|
	|ORDER BY
	|	LineNumber DESC";
	
	If Not SortInDescendingOrder Then
		QueryText = StrReplace(QueryText, "DESC", "ASC"); //@Query-part-1, @Query-part-2
	EndIf;
	
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	
	Return Selection;
	
EndFunction

// Parameters:
//  GoodsTableBeingProcessed - FormDataCollection, DocumentTabularSection.ConditionsOfCustomerRebates.Goods, DocumentTabularSection.ConditionsOfVendorRebates.Goods - Goods Table Being Processed
//  TempTableManager - TempTablesManager
// 
// Returns:
//  QueryResultSelection:
//  * LineNumber - Number
//  * Products - CatalogRef.Products
//  * Characteristic - CatalogRef.ItemsCharacteristics
//  * ItemVariantsAreUsed - Boolean
//  * QuantityBeginningOfAction - Number
//  * NumberOfExpiration - Number
//  * QuantityBasePrice - Number
//
Function SelectionOfGoodsRangesWithDifferentData(GoodsTableBeingProcessed, TempTableManager)
	
	CreateTemporaryGoodsTableToCheckRanges(GoodsTableBeingProcessed, TempTableManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	QueryText =
	"SELECT
	|	MIN(TTProducts_1.LineNumber) AS LineNumber,
	|	TTProducts_1.Products AS Products,
	|	TTProducts_1.Characteristic AS Characteristic,
	|	COUNT(DISTINCT TTProducts_1.ValidOnDate) AS QuantityBeginningOfAction,
	|	COUNT(DISTINCT TTProducts_1.ValidTo) AS NumberOfExpiration,
	|	COUNT(DISTINCT TTProducts_1.BasePrice) AS QuantityBasePrice
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|WHERE
	|NOT TTProducts_1.Canceled
	|
	|GROUP BY
	|	TTProducts_1.Characteristic,
	|	TTProducts_1.Products
	|
	|HAVING
	|	(COUNT(DISTINCT TTProducts_1.ValidOnDate) > 1
	|		OR COUNT(DISTINCT TTProducts_1.ValidTo) > 1
	|		OR COUNT(DISTINCT TTProducts_1.BasePrice) > 1)
	|
	|ORDER BY
	|	LineNumber";
	
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	
	Return Selection;
	
EndFunction

#EndRegion

#Region PropertiesByRanges

// Returns:
// 	ValueTable:
// 		* PropertyValue - DefinedType.RebateItemPropertyTypes
//  
Function NewTableOfPropertiesByRangesToBeProcessed()
		
	Table_For_Processing = New ValueTable;
	Table_For_Processing.Columns.Add(
		"PropertyValue",
		Metadata.DefinedTypes.RebateItemPropertyTypes.Type);
	
	Return Table_For_Processing;
	
EndFunction

// Parameters:
//  ProcessedTable - FormDataCollection, DocumentTabularSection.ConditionsOfCustomerRebates.ProductProperties_, DocumentTabularSection.ConditionsOfVendorRebates.ProductProperties_ - table being processed
//  TempTableManager - TempTablesManager
// 
Procedure CreateTemporaryPropertyTableForCheckingRanges(ProcessedTable, TempTableManager)
	
	If TempTableManager.Tables.Find("TTNomenclatureProperties") <> Undefined Then
		Return;
	EndIf;
	
	TableData = ProcessedTable.Unload();
	
	RequestForTTItemProperties = New Query;
	RequestForTTItemProperties.TempTablesManager = TempTableManager;
	
	QueryText =
	"SELECT
	|	PropertyData.LineNumber AS LineNumber,
	|	PropertyData.PropertyValue AS PropertyValue,
	|	PropertyData.ValidOnDate AS ValidOnDate,
	|	PropertyData.ValidTo AS ValidTo,
	|	PropertyData.CountPlan AS CountPlan,
	|	PropertyData.BasePrice AS BasePrice,
	|	PropertyData.Percent AS Percent,
	|	PropertyData.Canceled AS Canceled
	|INTO TTNomenclatureProperties
	|FROM
	|	&ProcessedTable AS PropertyData";
	
	RequestForTTItemProperties.Text = QueryText;
	RequestForTTItemProperties.SetParameter("ProcessedTable", TableData);
	RequestForTTItemProperties.Execute();
	
EndProcedure

// Parameters:
//  ProcessedTable - FormDataCollection, DocumentTabularSection.ConditionsOfCustomerRebates.ProductProperties_, DocumentTabularSection.ConditionsOfVendorRebates.ProductProperties_ - table being processed
//  TempTableManager - TempTablesManager
//  SortInDescendingOrder - Boolean
// 
// Returns:
//  QueryResultSelection:
//  * LineNumber - Number
//  * PropertyValue- DefinedType.RebateItemPropertyTypes
//
Function SelectingPropertiesWithoutInitialRange(ProcessedTable, TempTableManager, SortInDescendingOrder = False)
	
	CreateTemporaryPropertyTableForCheckingRanges(ProcessedTable, TempTableManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	QueryText =
	"SELECT
	|	MIN(TTNomenclatureProperties.LineNumber) AS LineNumber,
	|	TTNomenclatureProperties.PropertyValue AS PropertyValue
	|FROM
	|	TTNomenclatureProperties AS TTNomenclatureProperties
	|WHERE
	|NOT TTNomenclatureProperties.Canceled
	|
	|GROUP BY
	|	TTNomenclatureProperties.PropertyValue
	|
	|HAVING
	|	MIN(CASE
	|			WHEN TTNomenclatureProperties.CountPlan <> 0
	|				THEN 1
	|			ELSE 0
	|		END) > 0
	|
	|ORDER BY
	|	LineNumber DESC";
	
	If Not SortInDescendingOrder Then
		QueryText = StrReplace(QueryText, "DESC", "ASC"); //@Query-part-1, @Query-part-2
	EndIf;
	
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	
	Return Selection;
	
EndFunction

// Parameters:
//  ProcessedTable - FormDataCollection, DocumentTabularSection.ConditionsOfCustomerRebates.ProductProperties_, DocumentTabularSection.ConditionsOfVendorRebates.ProductProperties_ - table being processed
//  TempTableManager - TempTablesManager
// 
// Returns:
//  QueryResultSelection:
//  * LineNumber - Number
//  * PropertyValue - DefinedType.RebateItemPropertyTypes
//  * ItemVariantsAreUsed - Boolean
//  * QuantityBeginningOfAction - Number
//  * NumberOfExpiration - Number
//  * QuantityBasePrice - Number
//
Function SelectionOfRangeItemPropertiesWithDifferentData(ProcessedTable, TempTableManager)
	
	CreateTemporaryPropertyTableForCheckingRanges(ProcessedTable, TempTableManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	QueryText =
	"SELECT
	|	MIN(TTNomenclatureProperties.LineNumber) AS LineNumber,
	|	TTNomenclatureProperties.PropertyValue AS PropertyValue,
	|	COUNT(DISTINCT TTNomenclatureProperties.ValidOnDate) AS QuantityBeginningOfAction,
	|	COUNT(DISTINCT TTNomenclatureProperties.ValidTo) AS NumberOfExpiration,
	|	COUNT(DISTINCT TTNomenclatureProperties.BasePrice) AS QuantityBasePrice
	|FROM
	|	TTNomenclatureProperties AS TTNomenclatureProperties
	|WHERE
	|NOT TTNomenclatureProperties.Canceled
	|
	|GROUP BY
	|	TTNomenclatureProperties.PropertyValue
	|
	|HAVING
	|	(COUNT(DISTINCT TTNomenclatureProperties.ValidOnDate) > 1
	|		OR COUNT(DISTINCT TTNomenclatureProperties.ValidTo) > 1
	|		OR COUNT(DISTINCT TTNomenclatureProperties.BasePrice) > 1)
	|
	|ORDER BY
	|	LineNumber";
	
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	
	Return Selection;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion