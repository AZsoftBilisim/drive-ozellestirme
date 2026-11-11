#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)

	EmployeeResponsible = Users.CurrentUser();
	
	TypeFillingData = TypeOf(FillingData);
	If TypeFillingData = Type("Structure") Then
	
		If FillingData.Property("FillInValues") 
			And FillingData.Property("ProductCategory") 
			And ValueIsFilled(FillingData.ProductCategory)
			And FillingData.Property("Attribute")
			And ValueIsFilled(FillingData.Attribute) Then
			
			FillingVariant = Documents.SalesPlansAllocationBaseByCategories.FillingVariant(FillingData.ProductCategory, FillingData.Attribute);
			
			If TypeOf(FillingData.Attribute) = Type("String") Then
				
				AttributesStructure1 = Documents.SalesPlansAllocationBaseByCategories.GetDetailsForRegulations();
				
				AttributeStructure = Undefined;
				AttributesStructure1.Property(FillingData.Attribute, AttributeStructure);
				
				If AttributeStructure = Undefined Then
					
					Return;
					
				EndIf;
				
				Standards = StandardsByAttributes;
				
			Else
				
				Standards = StandardsByProperties;
				
			EndIf; 
			
			OnDate = '00010101';
			If Not FillingData.Property("ValidityStartDate", OnDate) Then
				OnDate = CurrentSessionDate();
			EndIf;
			
			Documents.SalesPlansAllocationBaseByCategories.FillTableOfStandardsWithAllValues(Standards, FillingData.ProductCategory, FillingData.Attribute, OnDate);
			
		EndIf; 
	
	EndIf; 
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	SalesPlansAllocationBaseByCategories.Ref
	|FROM
	|	Document.SalesPlansAllocationBaseByCategories AS SalesPlansAllocationBaseByCategories
	|WHERE
	|	SalesPlansAllocationBaseByCategories.Posted
	|	AND SalesPlansAllocationBaseByCategories.ValidityStartDate = &ValidityStartDate
	|	AND SalesPlansAllocationBaseByCategories.ProductCategory = &ProductCategory
	|	AND SalesPlansAllocationBaseByCategories.Attribute = &Attribute
	|	AND SalesPlansAllocationBaseByCategories.Ref <> &Ref";
	
	Query.SetParameter("ValidityStartDate", ValidityStartDate);
	Query.SetParameter("Attribute", Attribute);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("ProductCategory", ProductCategory);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		If Operation = Enums.TransactionsOfStandardsAllocation.StandardLock Then
			ErrorText = NStr("vi = 'Vào ngày cụ thể phong tỏa thao tác, đã nhập chứng từ đối với thể loại hàng hóa này và mục tin.';
							|ru = 'На указанную дату блокировки действия уже введен документ для этой товарной категории и реквизита.';
							|en = 'Document for this product category and attribute is already entered on the specified action lock date.'; fa = 'Document for this product category and attribute is already entered on the specified action lock date.';
							|it = 'Alla data del blocco di azione indicata è già inserito un documento per questi categoria merceologica e requisito.';
							|pl = 'Na wskazaną datę blokowania działania już jest wprowadzony dokument dla tej kategorii produktów i atrybutu.';
							|tr = 'Belirtilen kilitleme başlangıç tarihinde ürün kategorisi ve öznitelik için bir belge halihazırda girilmiş.'");
		Else
			ErrorText = NStr("vi = 'Vào ngày cụ thể bắt đầu hiệu lực, đã nhập chứng từ đối với thể loại hàng hóa và mục tin.';
							|ru = 'На указанную дату начала действия уже введен документ для этой товарной категории и реквизита.';
							|en = 'Document for this product category and attribute is already entered on the specified effective date.'; fa = 'Document for this product category and attribute is already entered on the specified effective date.';
							|it = 'Alla data dell''inizio di azione indicata è già inserito un documento per questi categoria merceologica e requisito.';
							|pl = 'Na wskazaną datę początku działania jest już wprowadzony dokument dla tej kategorii towarowej i atrybutu.';
							|tr = 'Belirtilen eylem başlangıç tarihinde ürün kategorisi ve öznitelik için bir belge halihazırda girilmiş.'");
		EndIf;
		
		CommonClientServer.MessageToUser(
			ErrorText, 
			Ref, 
			"ValidityStartDate",
			"Object",
			Cancel);
	
	EndIf; 

	If Operation = Enums.TransactionsOfStandardsAllocation.StandardLock Then
		Return;
	EndIf; 
	
	FillingVariant = Documents.SalesPlansAllocationBaseByCategories.FillingVariant(ProductCategory, Attribute);
	
	ErrorTextForAmountOfShares = NStr("vi = 'Cần chỉ ra ít nhất một tỷ lệ phân bổ.';
										|ru = 'Необходимо указать хотя бы одну долю распределения.';
										|en = 'Specify at least one allocation share.'; fa = 'Specify at least one allocation share.';
										|it = 'È necessario specificare almeno una quota di ripartizione.';
										|pl = 'Należy wskazać chociażby jeden udział przydziału.';
										|tr = 'En az bir paylaştırma payı belirtmek şart.'");
	
	If FillingVariant = 0 Then
		Standards = StandardsByAttributes;
		NameOfStandardsField = "StandardsByAttributes";
		 
	Else
		Standards = StandardsByProperties;
		NameOfStandardsField = "StandardsByProperties";
	EndIf;
	
	AmountOfShares = Standards.Total("AllocationPercentage");
	If AmountOfShares = 0 And Standards.Count() > 0 Then
		CommonClientServer.MessageToUser(ErrorTextForAmountOfShares, 
			Ref, 
			CommonClientServer.PathToTabularSection(NameOfStandardsField,1, "AllocationPercentage"),
			"Object",
			Cancel);
	EndIf; 
	
	CheckingStandards = Standards.Unload(,"Value");
	CheckingStandards.Columns.Add("Count", TMCommonUse.GetDescriptionOfNumberTypes(5,0));
	
	For Each TSRow In CheckingStandards Do
		TSRow.Count = 1;
	EndDo;
	
	CheckingStandards.GroupBy("Value", "Count");
	
	DuplicateErrorText = NStr("vi = 'Giá trị ""%Value%"" đã có trong danh sách định mức.';
								|ru = 'Значение ""%Value%"" уже присутствует в списке нормативов.';
								|en = 'The ""%Value%"" value already exists in the standard list.'; fa = 'The ""%Value%"" value already exists in the standard list.';
								|it = 'Valore ""%Value%"" è già presente nell''elenco dei normativi.';
								|pl = 'Wartość ""%Value%"" już jest w liście normatywów.';
								|tr = '""%Value%"" anlamı standart listesinde zaten mevcut.'");
	
	For Each TSRow In CheckingStandards Do
		If TSRow.Count > 1 Then
		
			FoundRows = Standards.FindRows(New Structure("Value", TSRow.Value));
			
			If FoundRows.Count() > 1 Then
				
				IndexOf = 1;
				While IndexOf <= FoundRows.UBound() Do
					
					FoundRow = FoundRows[IndexOf];
					
					CommonClientServer.MessageToUser(
						StrReplace(
							DuplicateErrorText, 
							"%Value%", 
							?(ValueIsFilled(FoundRow.Value), FoundRow.Value, NStr("vi = '<Giá trị trống>';
																					|ru = '<Пустое значение>';
																					|en = '<empty value>'; fa = '<empty value>';
																					|it = '<Valore vuoto>';
																					|pl = '<pusta wartość>';
																					|tr = '<Boş değer>'"))), 
						Ref, 
						CommonClientServer.PathToTabularSection(NameOfStandardsField,FoundRow.LineNumber, "Value"),
						"Object",
						Cancel);
					
					IndexOf = IndexOf + 1;
				EndDo; 
				
			EndIf; 
			
		EndIf; 
	EndDo;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Operation) Then
	
		Operation = Enums.TransactionsOfStandardsAllocation.SetStandard;
	
	EndIf; 
	
	FillingVariant = Documents.SalesPlansAllocationBaseByCategories.FillingVariant(ProductCategory, Attribute);
	If FillingVariant = 0 Then
		StandardsByProperties.Clear();
		
		If ValueIsFilled(Attribute) Then
		
			AttributesStructure1 = Documents.SalesPlansAllocationBaseByCategories.GetDetailsForRegulations(False);
			
			AttributeStructure = Undefined;
			AttributesStructure1.Property(Attribute, AttributeStructure);
			If AttributeStructure = Undefined Then
				TypeDescription = New TypeDescription("Undefined");
			Else
				TypeDescription = New TypeDescription(AttributeStructure.AttributeType);
			EndIf; 
		
		EndIf; 
		
	Else
		StandardsByAttributes.Clear();
		TypeDescription = Common.ObjectAttributeValue(Attribute, "ValueType");
	EndIf;
	
	AmountOfShares = StandardsByAttributes.Total("AllocationPercentage");
	
	For Each TSRow In StandardsByAttributes Do
	
		TSRow.NormalizedPercentage = ?(AmountOfShares>0, TSRow.AllocationPercentage/AmountOfShares,0);
		
		TSRow.ThisIsAnEmptyValue = False;
		If Not ValueIsFilled(TSRow.Value) Then
			TSRow.Value = TypeDescription.AdjustValue(Undefined);
			TSRow.ThisIsAnEmptyValue = True;
		EndIf;
		
	EndDo; 
	
	AmountOfShares = StandardsByProperties.Total("AllocationPercentage");
	
	For Each TSRow In StandardsByProperties Do
	
		TSRow.NormalizedPercentage = ?(AmountOfShares>0, TSRow.AllocationPercentage/AmountOfShares,0);
		
		TSRow.ThisIsAnEmptyValue = False;
		If Not ValueIsFilled(TSRow.Value) Then
			TSRow.Value = TypeDescription.AdjustValue(Undefined);
			TSRow.ThisIsAnEmptyValue = True;
		EndIf; 
	
	EndDo;
	
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

#EndIf