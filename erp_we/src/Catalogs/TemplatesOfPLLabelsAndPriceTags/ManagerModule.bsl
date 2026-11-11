#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  FullObjectName - String - the name of the object to be filled in for.
//  Settings - Structure:
//    * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
//    * PredefinedData - ValueTable - the data filled in in the procedure for the initial filling of the elements.
//
Procedure OnSetUpInitialItemsFilling(FullObjectName, Settings) Export
	Settings.OnInitialItemFilling = False;
EndProcedure

// The procedure fills in predefined elements in the directory Templates of labels and price tags.
//
Procedure OnInitialItemsFilling() Export
	
	TemplateDescriptions = TemplateDescriptions();
	
	BeginTransaction();
	Try
	
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED
			|	TemplatesOfPLLabelsAndPriceTags.Ref AS Ref,
			|	TemplatesOfPLLabelsAndPriceTags.PredefinedDataName AS PredefinedDataName
			|FROM
			|	Catalog.TemplatesOfPLLabelsAndPriceTags AS TemplatesOfPLLabelsAndPriceTags
			|WHERE
			|	TemplatesOfPLLabelsAndPriceTags.Predefined";
		
		QueryResult = Query.Execute();
		
		Block = New DataLock();
		LockItem = Block.Add("Catalog.TemplatesOfPLLabelsAndPriceTags");
		LockItem.DataSource = QueryResult;
		LockItem.UseFromDataSource("Ref", "Ref");
		Block.Lock();
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			TemplateObject1 = Selection.Ref.GetObject(); // CatalogObject.TemplatesOfPLLabelsAndPriceTags
			TemplateObject1.XMLTemplateDetails = TemplateDescriptions[Selection.PredefinedDataName];
			TemplateObject1.Write();
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		CommonCEL.WriteErrorToEventLog(
			NStr("vi = 'Điền phần tử định trước';
				|ru = 'Заполнение предопределенных элементов';
				|en = 'Fill predefined items'; fa = 'Fill predefined items';
				|it = 'Compilazione degli elementi predefiniti';
				|pl = 'Wypełnienie predefiniowanych elementów';
				|tr = 'Önceden tanımlanan öğelerin doldurulması'", CommonCEL.DefaultLanguageCode()));
		
	EndTry;
	
EndProcedure

#EndRegion 

#Region Private

Function TemplateDescriptions()
	
	TemplateDescriptions = New Map();
	Template = Catalogs.TemplatesOfPLLabelsAndPriceTags.GetTemplate("LabelTemplates");
	
	For LineNumber = 1 To Template.TableHeight Do
		
		PredefinedItemName = Template.Area(LineNumber, 1, LineNumber, 1).Text;
		XMLTemplateDetails = Template.Area(LineNumber, 2, LineNumber, 2).Text;
		
		If Not IsBlankString(PredefinedItemName) = "" Then
			TemplateDescriptions.Insert(PredefinedItemName, XMLTemplateDetails);
		EndIf;
		
	EndDo;
	
	Return TemplateDescriptions;
	
EndFunction

#EndRegion 

#EndIf
 
