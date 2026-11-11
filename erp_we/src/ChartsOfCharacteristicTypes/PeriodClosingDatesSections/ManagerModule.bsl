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

// CloudTechnology.ExportImportData

// Returns the catalog attributes that naturally form a catalog item key.
//
// Returns:
//  Array of String - Array of attribute names used to generate a natural key.
//
Function NaturalKeyFields() Export
	
	Result = New Array;
	Result.Add("Description");
	
	Return Result;
	
EndFunction

// End CloudTechnology.ExportImportData

#EndRegion

#EndRegion

#Region Private

// Returns:
//  FixedStructure:
//    * NoSectionsAndObjects - Boolean
//    * AllSectionsWithoutObjects - Boolean
//    * SingleSection - ChartOfCharacteristicTypesRef.PeriodClosingDatesSections
//    * ShowSections - Boolean
//    * Sections - FixedMap of KeyAndValue:
//        ** Key - String
//        ** Value - FixedStructure:
//             *** Name - String
//             *** Presentation - String
//             *** Ref - ChartOfCharacteristicTypesRef.PeriodClosingDatesSections
//             *** ObjectsTypes - FixedArray
//    * SectionsWithoutObjects - FixedArray
//
Function ClosingDatesSectionsProperties() Export
	
	Sections = New ValueTable;
	Sections.Columns.Add("Name",           New TypeDescription("String",,,, New StringQualifiers(150)));
	Sections.Columns.Add("Id", New TypeDescription("UUID"));
	Sections.Columns.Add("Presentation", New TypeDescription("String"));
	Sections.Columns.Add("ObjectsTypes",  New TypeDescription("Array"));
	
	SSLSubsystemsIntegration.OnFillPeriodClosingDatesSections(Sections);
	PeriodClosingDatesOverridable.OnFillPeriodClosingDatesSections(Sections);
	
	ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Lỗi trong thủ tục %1 của mô-đun chung %2.';
			|ru = 'Ошибка в процедуре %1 общего модуля %2.';
			|en = 'Error in procedure %1 of common module %2.'; fa = 'Error in procedure %1 of common module %2.';
			|it = 'Errore di procedura %1 del modulo comune %2.';
			|pl = 'Błąd w procedurze %1 wspólnego modułu %2.';
			|tr = '%2genel modülün %1prosedüründe hata.'"),
		"OnFillPeriodClosingDatesSections", "PeriodClosingDatesOverridable")
		+ Chars.LF + Chars.LF;
	
	ClosingDatesSections     = New Map;
	SectionsWithoutObjects    = New Array;
	AllSectionsWithoutObjects = True;
	
	ClosingDatesObjectsTypes = New Map;
	Types = Metadata.ChartsOfCharacteristicTypes.PeriodClosingDatesSections.Type.Types();
	For Each Type In Types Do
		If Type = Type("EnumRef.PeriodClosingDatesPurposeTypes")
		 Or Type = Type("ChartOfCharacteristicTypesRef.PeriodClosingDatesSections")
		 Or Not Common.IsReference(Type) Then
			Continue;
		EndIf;
		ClosingDatesObjectsTypes.Insert(Type, True);
	EndDo;
	
	For Each Section In Sections Do
		If Not ValueIsFilled(Section.Name) Then
			Raise ErrorTitle + NStr("vi = 'Chưa điền tên phân hệ ngày cấm.';
									|ru = 'Имя раздела дат запрета не заполнено.';
									|en = 'Name is required for the period-end closing date section.'; fa = 'Name is required for the period-end closing date section.';
									|it = 'Il nome della sezione delle date di divieto non è compilato.';
									|pl = 'Nie wypełniono rozdziału dat zakazu.';
									|tr = 'Dönem sonu kapanış tarihi için ad doldurulmadı.'");
		EndIf;
		
		If ClosingDatesSections.Get(Section.Name) <> Undefined Then
			Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xác định tên phân hệ ngày cấm ""%1"".';
					|ru = 'Имя раздела дат запрета ""%1"" уже определено.';
					|en = '""%1"" period-end closing date section already has a name.'; fa = '""%1"" period-end closing date section already has a name.';
					|it = 'Il nome della sezione delle date di divieto ""%1"" è già stato definito.';
					|pl = 'Nazwa rozdziału dat zakazu ""%1"" jest już określona.';
					|tr = '""%1"" dönem sonu kapanış tarihi bölümü için ad zaten belirlendi.'"),
				Section.Name);
		EndIf;
		
		If Not ValueIsFilled(Section.Id) And Section.Name <> "SingleDate" Then
			Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa điền tên định danh của phân hệ ngày cấm ""%1"".';
					|ru = 'Идентификатор раздела дат запрета ""%1"" не заполнен.';
					|en = 'ID is required for ""%1"" period-end closing date section.'; fa = 'ID is required for ""%1"" period-end closing date section.';
					|it = 'L''identificativo della sezione delle date di divieto ""%1"" non è compilato.';
					|pl = 'Nie wypełniono rozdziału dat zakazu ""%1"".';
					|tr = '""%1"" dönem sonu kapanış tarihi bölümü kimliği doldurulmadı.'"),
				Section.Name);
		EndIf;
		
		SectionReference = GetRef(Section.Id);
		
		If ClosingDatesSections.Get(SectionReference) <> Undefined Then
			SectionClosingDates = ClosingDatesSections.Get(SectionReference); // See SectionProperties
			Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tên định danh ""%1"" của phân hệ ngày bị cấm
				           | ""%2"" được sử dụng cho phân hệ ""%3"".';
				           |ru = 'Идентификатор ""%1"" раздела дат запрета
				           |""%2"" уже используется для раздела ""%3"".';
				           |en = 'ID ""%1"" of ""%2"" period-end closing date section
				           |has already been assigned to ""%3"" section.'; fa = 'ID ""%1"" of ""%2"" period-end closing date section
				           |has already been assigned to ""%3"" section.';
				           |it = 'L''identificativo ""%1"" della sezione delle date di divieto
				           |""%2"" è già utilizzato per la sezione ""%3"".';
				           |pl = 'Identyfikator ""%1"" rozdziału dat zakazu
				           |""%2"" jest już używana do rozdziału ""%3"".';
				           |tr = '""%2"" dönem sonu kapanış tarihi bölümünün 
				           |""%1"" kimliği ""%3"" bölümü için zaten kullanılıyor.'"),
				Section.Id, Section.Name, SectionClosingDates.Name);
		EndIf;
		
		ObjectsTypes = New Array;
		For Each Type In Section.ObjectsTypes Do
			AllSectionsWithoutObjects = False;
			If Not Common.IsReference(Type) Then
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Kiểu ""%1"" được chỉ định như là kiểu đối tượng cho phân hệ ngày bị cấm ""%2"".
					           |Tuy nhiên, đây không phải là kiểu tham chiếu.';
					           |ru = 'Тип ""%1"" указан, как тип объектов для раздела дат запрета ""%2"".
					           |Однако это не тип ссылки.';
					           |en = 'Object type for ""%2"" period-end closing date section is defined as ""%1"". 
					           |But it is not a reference type.'; fa = 'Object type for ""%2"" period-end closing date section is defined as ""%1"". 
					           |But it is not a reference type.';
					           |it = 'Il tipo ""%1"" è indicato come tipo di oggetti per la sezione delle date di divieto ""%2"".
					           | Tuttavia, questo non è il tipo di link.';
					           |pl = 'Typ ""%1"" został określony jako typ obiektów dla rozdziału dat zakazu ""%2"".
					           |Jednak nie jest to typ odnośnika.';
					           |tr = '""%1"" türü, ""%2"" yasak tarihleri bölümü için nesne türü olarak belirlendi.
					           |Ancak bu referans türü değil.'"),
					String(Type), Section.Name);
			EndIf;
			If ClosingDatesObjectsTypes.Get(Type) = Undefined Then
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Kiểu đối tượng ""%1"" của phân hệ ngày bị cấm ""%2""
					           | chưa chỉ định trong thuộc tính ""Kiểu"" của hệ thống dạng đặc tính ""Phân hệ ngày cấm thay đổi"".';
					           |ru = 'Тип объектов ""%1"" раздела дат запрета ""%2""
					           |не указан в свойстве ""Тип"" плана видов характеристик ""Разделы дат запрета изменения"".';
					           |en = 'Property ""Type"" in chart of characteristic types ""Period-end closing dates sections""
					           |requires ""%1"" object type of ""%2"" period-end closing dates section.'; fa = 'Property ""Type"" in chart of characteristic types ""Period-end closing dates sections""
					           |requires ""%1"" object type of ""%2"" period-end closing dates section.';
					           |it = 'Il tipo di oggetti ""%1"" della sezione delle dati di divieto ""%2""
					           | non è indicato nella proprietà ""Tipo"" del piano del tipo di caratteristiche ""Sezioni delle dati di divieto di modifica"".';
					           |pl = 'Typ obiektów ""%1"" rozdziału dat zakazu ""%2""
					           | nie został określony we właściwości ""Typ"" planu rodzajów charakterystyk ""Rozdziały dat zakazu zmian"".';
					           |tr = '""%1"" yasak tarihleri ""%2"" bölümünün nesne türü 
					           | ""Değişiklik yasağı tarihlerinin bölümleri"" özellik türleri planının ""Tür"" özelliğinde belirtilmedi.'"),
					String(Type), Section.Name);
			EndIf;
			TypeMetadata = Metadata.FindByType(Type);
			FullName = TypeMetadata.FullName();
			ObjectManager = Common.ObjectManagerByFullName(FullName);
			TypeProperties = New Structure;
			TypeProperties.Insert("EmptyRef",  ObjectManager.EmptyRef());
			TypeProperties.Insert("FullName",     FullName);
			TypeProperties.Insert("Presentation", String(Type));
			ObjectsTypes.Add(New FixedStructure(TypeProperties));
		EndDo;
		
		SectionProperties = SectionProperties(SectionReference, Section.Name, Section.Presentation, New FixedArray(ObjectsTypes));
		SectionProperties = New FixedStructure(SectionProperties);
		ClosingDatesSections.Insert(SectionProperties.Name,    SectionProperties);
		ClosingDatesSections.Insert(SectionProperties.Ref, SectionProperties);
		
		If ObjectsTypes.Count() = 0 Then
			SectionsWithoutObjects.Add(Section.Name);
		EndIf;
	EndDo;
	
	// Adding a blank section (a common date).
	SectionProperties = SectionProperties(EmptyRef());
	SectionProperties = New FixedStructure(SectionProperties);
	ClosingDatesSections.Insert(SectionProperties.Name,    SectionProperties);
	ClosingDatesSections.Insert(SectionProperties.Ref, SectionProperties);
	
	Properties = New Structure;
	Properties.Insert("Sections",               New FixedMap(ClosingDatesSections));
	Properties.Insert("SectionsWithoutObjects",    New FixedArray(SectionsWithoutObjects));
	Properties.Insert("AllSectionsWithoutObjects", AllSectionsWithoutObjects);
	Properties.Insert("NoSectionsAndObjects",  Sections.Count() = 0);
	Properties.Insert("SingleSection",    ?(Sections.Count() = 1,
	                                             ClosingDatesSections[Sections[0].Name].Ref,
	                                             EmptyRef()));
	Properties.Insert("ShowSections",     Properties.AllSectionsWithoutObjects
	                                           Or Not ValueIsFilled(Properties.SingleSection));
	
	Return New FixedStructure(Properties);
	
EndFunction

// Returns:
//   Structure:
//     * ObjectsTypes - FixedArray
//     * Presentation - String
//     * Ref - ChartOfCharacteristicTypesRef.PeriodClosingDatesSections
//     * Name - String
//
Function SectionProperties(Ref, Val Name = "", Val Presentation = "", Val ObjectsTypes = Undefined) Export
	
	SectionProperties = New Structure;
	SectionProperties.Insert("Name", Name);
	SectionProperties.Insert("Ref", Ref);
	SectionProperties.Insert("Presentation", ?(IsBlankString(Presentation), NStr("vi = 'Ngày chung';
																				|ru = 'Общая дата';
																				|en = 'Single date'; fa = 'Single date';
																				|it = 'Data condivisa';
																				|pl = 'Wspólna data';
																				|tr = 'Ortak tarih'"), Presentation));
	SectionProperties.Insert("ObjectsTypes", ?(ObjectsTypes = Undefined, New FixedArray(New Array), ObjectsTypes));
	Return SectionProperties;

EndFunction

#EndRegion

#EndIf