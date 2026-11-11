///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Registers all report options with snapshots for export.
//
// Parameters:
//  ExchangeNode - ExchangePlanRef - Exchange plan node for which changes are being registered.
//
Procedure RecordDataChanges(ExchangeNode) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	ReportsSnapshots.Variant AS Variant
	|FROM
	|	InformationRegister.ReportsSnapshots AS ReportsSnapshots
	|WHERE
	|	ReportsSnapshots.Variant REFS Catalog.ReportsOptions";
	
	ExchangePlanContent = ExchangeNode.Metadata().Content;
	For Each ExchangePlanContentItem In ExchangePlanContent Do
		
		If ExchangePlanContentItem.Metadata = Metadata.Catalogs.ReportsOptions Then
			// @skip-check query-in-loop - One-time data processing
			ReferencesArrray = Query.Execute().Unload().UnloadColumn("Variant");
			ExchangePlans.RecordChanges(ExchangeNode, ReferencesArrray);
		Else
			ExchangePlans.RecordChanges(ExchangeNode,ExchangePlanContentItem.Metadata);
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns "True" if report snapshots are found for the standalone mode.
// 
// Parameters:
//  Source - CatalogObject
// 
// Returns:
//  Boolean
//
Function HasChangesForStandaloneMode(Source) Export
	
	If TypeOf(Source) = Type("CatalogObject.ReportsOptions") 
		And Not HasReportOptionSnapshots(Source.Ref) Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Register for export the report options and users associated with the snapshots. 
// 
// 
// Parameters:
//  Source - Arbitrary
//  Changes - Array
// 
Procedure RecordChangesForOfflineMode(Source, Changes) Export

	If TypeOf(Source) = Type("InformationRegisterRecordSet.ReportsSnapshots") Then
		For Each Record In Source Do
			Changes.Add(Record.Variant);
			Changes.Add(Record.User);
		EndDo;
	EndIf;
	
EndProcedure

// Exports report options, their snapshots, and related user information as XML.
//
// Parameters:
//  XMLWriter - XMLWriter
//  Data - Arbitrary - Data to be written as XML.
//
Procedure WriteReportsAsXML(XMLWriter, Data) Export
	
	If TypeOf(Data) = Type("CatalogObject.ReportsOptions") Then
		WriteReportOptionsAsXML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("CatalogObject.Users") Then
		WriteUsersAsXML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("InformationRegisterRecordSet.ReportsSnapshots") Then
		WriteReportSnapshotsAsXML(XMLWriter, Data);
	EndIf;

EndProcedure

// Imports report options, their snapshots, and related user information from XML.
//
// Parameters:
//  XMLReader - XMLReader
//
// Returns:
//  CatalogObject
//  Undefined - Read data prepared for writing.
//
Function ReadReportsFromXML(XMLReader) Export
	
	If XMLReader.Name = "CatalogObject.ReportsOptions" Then
		Return ReadReportOptionsFromXML(XMLReader);
	ElsIf XMLReader.Name = "CatalogObject.Users" Then
		Return ReadUsersFromXML(XMLReader);
	ElsIf XMLReader.Name = "InformationRegisterRecordSet.ReportsSnapshots" Then
		ReadReportSnapshotsFromXML(XMLReader);
	EndIf;
	Return Undefined;
	
EndFunction

#EndRegion

#Region Private

// Writes report snapshots as XML.
//
// Parameters:
//  XMLWriter - XMLWriter
//  Data - ValueTableRow - Report snapshot data.
//
Procedure WriteReportSnapshotsAsXML(XMLWriter, Data)
	
	If Data.Count() = 0 Then
		Return;
	EndIf;
	
	XMLWriter.WriteStartElement("InformationRegisterRecordSet.ReportsSnapshots");
	
	XMLWriter.WriteStartElement("User");
	XMLWriter.WriteText(String(Data[0].User.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Report");
	XMLWriter.WriteText(String(Data[0].Report.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ValueTypeReport");
	If TypeOf(Data[0].Report) = Type("CatalogRef.MetadataObjectIDs") Then
		XMLWriter.WriteText("MetadataObjectIDs");
	ElsIf TypeOf(Data[0].Report) = Type("CatalogRef.ExtensionObjectIDs") Then
		XMLWriter.WriteText("ExtensionObjectIDs");
	ElsIf Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		XMLWriter.WriteText("AdditionalReportsAndDataProcessors");
	EndIf;
	XMLWriter.WriteEndElement();

	XMLWriter.WriteStartElement("ReportVariant");
	XMLWriter.WriteText(String(Data[0].Variant.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("OptionValueType");
	XMLWriter.WriteText(?(TypeOf(Data[0].Variant) = Type("CatalogRef.ReportsOptions"), "ReportsOptions", ""));
	XMLWriter.WriteEndElement();

	XMLWriter.WriteStartElement("UserSettingsHash");
	XMLWriter.WriteText(Data[0].UserSettingsHash);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ReportResult");
	ReportResult = XDTOSerializer.WriteXDTO(Data[0].ReportResult);
	XDTOFactory.WriteXML(XMLWriter, ReportResult, "ValueStorage", "http://v8.1c.ru/8.1/data/core", ,
		XMLTypeAssignment.Explicit);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("UpdateDate");
	XMLWriter.WriteText(String(Data[0].UpdateDate));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("LastViewedDate");
	XMLWriter.WriteText(String(Data[0].LastViewedDate));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ReportUpdateError");
	XMLWriter.WriteText(String(Data[0].ReportUpdateError));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

// Writes report option data as XML.
//
// Parameters:
//  XMLWriter - XMLWriter
//  Data - CatalogRef.ReportsOptions
//
Procedure WriteReportOptionsAsXML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.ReportsOptions");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

// Writes user data as XML.
//
// Parameters:
//  XMLWriter - XMLWriter
//  Data - CatalogRef.ReportsOptions
//
Procedure WriteUsersAsXML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.Users");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("IBUserID");
	XMLWriter.WriteText(String(Data.IBUserID));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure ReadReportSnapshotsFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);

	User = Catalogs.Users.GetRef(New UUID(XDTODataObject.User));
	Report = Undefined;
	If XDTODataObject.ValueTypeReport = "MetadataObjectIDs" Then
		Report = Catalogs.MetadataObjectIDs.GetRef(
			New UUID(XDTODataObject.Report));
	ElsIf XDTODataObject.ValueTypeReport = "ExtensionObjectIDs" Then
		Report = Catalogs.ExtensionObjectIDs.GetRef(
			New UUID(XDTODataObject.Report));
	ElsIf Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
		ObjectManager = Common.ObjectManagerByFullName(ModuleAdditionalReportsAndDataProcessors.AdditionalReportTableName());
		Report = ObjectManager.GetRef(New UUID(XDTODataObject.Report));
	EndIf;
	If XDTODataObject.OptionValueType = "ReportsOptions" Then
		Variant = Catalogs.ReportsOptions.GetRef(New UUID(XDTODataObject.ReportVariant));
	Else
		Variant = Undefined;
	EndIf;

	RecordManager = InformationRegisters.ReportsSnapshots.CreateRecordManager();

	RecordManager.User = User;
	RecordManager.Report = Report;
	RecordManager.Variant = Variant;
	RecordManager.UserSettingsHash = XDTODataObject.UserSettingsHash;

	RecordManager.ReportResult = XDTODataObject.ReportResult.ValueStorage;
	RecordManager.UpdateDate = Date(XDTODataObject.UpdateDate);
	RecordManager.LastViewedDate = Date(XDTODataObject.LastViewedDate);

	RecordManager.ReportUpdateError = Boolean(XDTODataObject.ReportUpdateError);

	Try
		RecordManager.Write();
	Except
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể ghi lại ảnh chụp báo cáo %1 do: 
				 |%2';
				 |ru = 'Не удалось записать снимок отчета %1 по причине: 
				 |%2';
				 |en = 'Cannot save the %1 report snapshot due to: 
				 |%2'; fa = 'Cannot save the %1 report snapshot due to: 
				 |%2';
				 |it = 'Cannot save the %1 report snapshot due to: 
				 |%2';
				 |pl = 'Cannot save the %1 report snapshot due to: 
				 |%2';
				 |tr = '%1 raporu şu nedenle kaydedilemedi: 
				 |%2'"), ?(ValueIsFilled(Variant), Variant, Report), ErrorProcessing.DetailErrorDescription(
			ErrorInfo()));
#If MobileStandaloneServer Then
		Common.MessageToUser(MessageText);
#Else
		WriteLogEvent(NStr("vi = 'Kết nhập ảnh chụp báo cáo từ XML';
							|ru = 'Загрузка снимка отчета из XML';
							|en = 'Import a report snapshot from XML'; fa = 'Import a report snapshot from XML';
							|it = 'Import a report snapshot from XML';
							|pl = 'Import a report snapshot from XML';
							|tr = 'XML''den rapor ekran alıntısı yükleme'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, Metadata.InformationRegisters.ReportsSnapshots, , MessageText);
#EndIf
	EndTry;
	
EndProcedure

// Reads report options from XML.
//
// Parameters:
//  XMLReader - XMLReader
//
// Returns:
//  CatalogObject.ReportsOptions
//
Function ReadReportOptionsFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	DataReference = Catalogs.ReportsOptions.GetRef(New UUID(XDTODataObject.Ref));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Catalogs.ReportsOptions.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	Return Data;
	
EndFunction

// Reads user information from XML.
//
// Parameters:
//  XMLReader - XMLReader
//
// Returns:
//  CatalogObject.Users
//
Function ReadUsersFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	DataReference = Catalogs.Users.GetRef(New UUID(XDTODataObject.Ref));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Catalogs.Users.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	Data.IBUserID = New UUID(XDTODataObject.IBUserID);
	
	Return Data;
	
EndFunction

// Returns the flag indicating whether the given report option has snapshots.
//
// Parameters:
//  Variant - CatalogRef.ReportsOptions - Report option.
//
// Returns:
//  Boolean
//
Function HasReportOptionSnapshots(Variant)
	
	Query = New Query;
	Query.SetParameter("Variant", Variant);
	Query.Text =
	"SELECT TOP 1
	|	ReportsSnapshots.Variant AS Variant
	|FROM
	|	InformationRegister.ReportsSnapshots AS ReportsSnapshots
	|WHERE
	|	ReportsSnapshots.Variant = &Variant";
	
	Return Query.Execute().IsEmpty();
	
EndFunction

#EndRegion
