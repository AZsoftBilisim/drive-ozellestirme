///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Function DefineFormType(FormName) Export
	
	Return NationalLanguageSupportServer.DefineFormType(FormName);
	
EndFunction

Function ConfigurationUsesOnlyOneLanguage(PresentationsInTabularSection) Export
	
	If Metadata.Languages.Count() = 1 Then
		Return True;
	EndIf;
	
	If PresentationsInTabularSection Then
		Return False;
	EndIf;
	
	For LanguageSeqNumber = 1 To AdditionalLanguagesCount() Do
		If IsAdditionalLangUsed(LanguageSeqNumber) Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

Function ObjectContainsPMRepresentations(ReferenceOrFullMetadataName, AttributeName = "") Export
	
	If TypeOf(ReferenceOrFullMetadataName) = Type("String") Then
		MetadataObject = Common.MetadataObjectByFullName(ReferenceOrFullMetadataName);
		FullName = ReferenceOrFullMetadataName;
	Else
		MetadataObject = ReferenceOrFullMetadataName.Metadata();
		FullName = MetadataObject.FullName();
	EndIf;
	
	HaveTabularPart = False;
	If StrStartsWith(FullName, "Catalog")
		Or StrStartsWith(FullName, "Document")
		Or StrStartsWith(FullName, "ChartOfCharacteristicTypes")
		Or StrStartsWith(FullName, "Task")
		Or StrStartsWith(FullName, "BusinessProcess")
		Or StrStartsWith(FullName, "DataProcessor")
		Or StrStartsWith(FullName, "ChartOfCalculationTypes")
		Or StrStartsWith(FullName, "Report")
		Or StrStartsWith(FullName, "ChartOfAccounts")
		Or StrStartsWith(FullName, "ExchangePlan") Then
		
			HaveTabularPart = MetadataObject.TabularSections.Find("Presentations") <> Undefined;
			If HaveTabularPart And ValueIsFilled(AttributeName) Then
				HaveTabularPart = MetadataObject.TabularSections.Presentations.Attributes.Find(AttributeName) <> Undefined;
			EndIf;
		
	EndIf;
	
	Return HaveTabularPart;
	
EndFunction

Function LanguagesInfo() Export
	
	Result = New Structure;
	
	AdditionalLanguagesCount = AdditionalLanguagesCount();
	
	Result.Insert("Language0", Common.DefaultLanguageCode());
	Result.Insert("AdditionalLanguagesCount", AdditionalLanguagesCount);
	Result.Insert("DefaultLanguage", Common.DefaultLanguageCode());
	
	Used = New Structure;
	For LanguageSeqNumber = 1 To AdditionalLanguagesCount Do
		LanguageSuffixName = NationalLanguageSupportClientServer.LanguageSuffix(LanguageSeqNumber);
		LanguageCode = NationalLanguageSupportServer.InfobaseAdditionalLanguageCode(LanguageSeqNumber);
		Result.Insert(LanguageSuffixName, LanguageCode);
			
		Used.Insert(LanguageSuffixName,
			IsAdditionalLangUsed(LanguageSeqNumber) And ValueIsFilled(LanguageCode));
	EndDo;
	Result.Insert("Used", New FixedStructure(Used));
	
	Return New FixedStructure(Result);
	
EndFunction

Function InfoAboutLanguagesUsed() Export
	
	Used = New Structure;
	For LanguageSeqNumber = 1 To AdditionalLanguagesCount() Do
		LanguageSuffixName = NationalLanguageSupportClientServer.LanguageSuffix(LanguageSeqNumber);
		LanguageCode = NationalLanguageSupportServer.InfobaseAdditionalLanguageCode(LanguageSeqNumber);
			
		Used.Insert(LanguageSuffixName,
			IsAdditionalLangUsed(LanguageSeqNumber) And ValueIsFilled(LanguageCode));
	EndDo;
	
	Return New FixedStructure(Used);
	
EndFunction

Function LanguageSuffixByLanguageCode(Language) Export
	
	For LanguageSeqNumber = 1 To AdditionalLanguagesCount() Do
		
		ConstantName    =  NationalLanguageSupportServer.LanguageConstantName(LanguageSeqNumber);
		If StrCompare(Language, Constants[ConstantName].Get()) = 0
		   And IsAdditionalLangUsed(LanguageSeqNumber) Then
				Return NationalLanguageSupportClientServer.LanguageSuffix(LanguageSeqNumber);
		EndIf;
		
	EndDo;
	
	Return "";
	
EndFunction

Function AdditionalLanguagesCount() Export
	
	LanguageSeqNumber = 1;
	LanguagesCount     = Undefined;
	
	While LanguagesCount = Undefined Do
		
		If Metadata.Constants.Find(NationalLanguageSupportServer.LanguageConstantName(LanguageSeqNumber)) = Undefined
		 Or LanguageSeqNumber = 1000 Then
			LanguagesCount = LanguageSeqNumber - 1;
			Break;
		EndIf;
		
		LanguageSeqNumber = LanguageSeqNumber + 1;
		
	EndDo;
		
	Return LanguagesCount;
	
EndFunction

Function IsAdditionalLangUsed(LanguageSeqNumber) Export
	
	LanguageConstantName = NationalLanguageSupportServer.FunctionalOptionName(LanguageSeqNumber);
	If Metadata.Constants.Find(LanguageConstantName) <> Undefined 
	   And Constants[LanguageConstantName].Get() = True Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function MultilingualObjectAttributes(ObjectOrRef) Export
	
	ObjectType = TypeOf(ObjectOrRef);
	
	If ObjectType = Type("String") Then
		ObjectMetadata = Common.MetadataObjectByFullName(ObjectOrRef);
	ElsIf Common.IsReference(ObjectType) Then
		ObjectMetadata = ObjectOrRef.Metadata();
	Else
		ObjectMetadata = ObjectOrRef;
	EndIf;
	
	Return NationalLanguageSupportServer.DescriptionsOfObjectAttributesToLocalize(ObjectMetadata);
	
EndFunction

Function ThereareMultilingualDetailsintheHeaderoftheObject(MetadataObjectFullName) Export
	
	QueryText = "SELECT TOP 0
		|	*
		|FROM
		|	&MetadataObjectFullName AS SourceData";
	
	QueryText = StrReplace(QueryText, "&MetadataObjectFullName", MetadataObjectFullName);
	Query = New Query(QueryText);
	
	QueryResult = Query.Execute();
	
	For Each Column In QueryResult.Columns Do
		InfoAboutAttribute = NationalLanguageSupportServer.InfoAboutAttribute(Column.Name);
		If InfoAboutAttribute.Multilingual And Not InfoAboutAttribute.Deleted Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Returns the names of the multi-language attributes of the "Presentations" table.
// 
// Parameters:
//  FullMetadataObjectName - String
// 
// Returns:
//  FixedArray of String
//
Function TabularSectionMultilingualAttributes(FullMetadataObjectName) Export
	
	MetadataObject = Metadata.FindByFullName(FullMetadataObjectName);
	
	Result = New Array;
	For Each Attribute In MetadataObject.TabularSections.Presentations.Attributes Do
		If StrCompare(Attribute.Name, "LanguageCode") = 0 Or StrStartsWith(Attribute.Name, "Delete") Then
			Continue;
		EndIf;
		Result.Add(Attribute.Name);
	EndDo;
	
	Return New FixedArray(Result);
	
EndFunction

Function GettingSelectionDataQueryText(FullMetadataObjectName, ItemsAndGroupsSelectionType) Export
	
	MetadataObject = Metadata.FindByFullName(FullMetadataObjectName);
	FilterConditions = NationalLanguageSupportServer.SearchTermsByLocalizedFieldsForChoiceDataGetQuery(MetadataObject);
	
	QueryTemplate = 
	"SELECT ALLOWED TOP 20
	|	Table.Ref AS Ref
	|FROM
	|	&ObjectName AS Table
	|WHERE
	|	&ConditionsOfGroup
	|	AND (&FilterConditions)";
	
	TheConditionForTheGroup = "TRUE";
	
	SupportsHierarchy = (Metadata.Catalogs.Contains(MetadataObject)
		Or Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject));
	
	ObjectHierarchical = SupportsHierarchy And MetadataObject.Hierarchical;
	
	If ObjectHierarchical And ValueIsFilled(ItemsAndGroupsSelectionType)  Then
		
		If ItemsAndGroupsSelectionType = "Items" Then
			TheConditionForTheGroup = "NOT Table.IsFolder";
		ElsIf ItemsAndGroupsSelectionType = "Groups" Then
			TheConditionForTheGroup = "Table.IsFolder";
		EndIf;
		
	EndIf;
	
	QueryText = StrReplace(QueryTemplate, "&ObjectName",    MetadataObject.FullName());
	QueryText = StrReplace(QueryText,  "&ConditionsOfGroup", TheConditionForTheGroup);
	QueryText = StrReplace(QueryText,  "&FilterConditions", FilterConditions);
	
	Return QueryText;
	
EndFunction

#EndRegion