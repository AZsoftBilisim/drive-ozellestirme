///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See CommonOverridable.OnAddMetadataObjectsRenaming.
Procedure OnAddMetadataObjectsRenaming(Renamings) Export

	Common.AddRenaming(Renamings, "2.3.3.5", 
		"Role.UsingSubordinationStructure", "Role.ViewRelatedDocuments", "StandardSubsystems");

EndProcedure

// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject
//
// Parameters:
//   AttachableCommandsKinds - See AttachableCommandsOverridable.OnDefineAttachableCommandsKinds.AttachableCommandsKinds
//
Procedure OnDefineAttachableCommandsKinds(AttachableCommandsKinds) Export
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		Return;
	EndIf;
	
	Kind = AttachableCommandsKinds.Add();
	Kind.Name         = "Reports";
	Kind.SubmenuName  = "ReportsSubmenu";
	Kind.Title   = NStr("vi = 'Báo cáo';
						|ru = 'Отчеты';
						|en = 'Reports'; fa = 'گزارش‌ها';
						|it = 'Report';
						|pl = 'Reports';
						|tr = 'Raporlar'");
	Kind.Order     = 50;
	Kind.Picture    = PictureLib.Report;
	Kind.Representation = ButtonRepresentation.PictureAndText;

EndProcedure

// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export

	FormMetadata = Metadata.CommonForms.RelatedDocuments;
	If Not AccessRight("View", FormMetadata) Then
		Return;
	EndIf;

	CommandParameterType = CommandParameterType(Sources);
	If CommandParameterType = Undefined Then
		Return;
	EndIf;

	Command = Commands.Add();
	Command.Presentation      = NStr("vi = 'Cấu trúc trực thuộc';
									|ru = 'Связанные документы';
									|en = 'Related documents'; fa = 'اسناد مرتبط';
									|it = 'Documenti correlati';
									|pl = 'Dokumenty powiązane';
									|tr = 'İlgili belgeler'");
	Command.Kind                = "Reports";
	Command.MultipleChoice = False;
	Command.FormParameterName  = "FilterObject";
	Command.FormName           = FormMetadata.FullName();
	Command.Importance           = "SeeAlso";
	Command.ParameterType       = CommandParameterType;
	Command.Shortcut    = New Shortcut(Key.S, False, True, True);
	Command.Picture           = PictureLib.SubordinationStructure;
	Command.Order = 100;

EndProcedure

#EndRegion

#Region Private

Function CommandParameterType(Sources)

	SourcesTypes = New Array;
	FillSourcesTypes(SourcesTypes, Sources.Rows);
	SourcesTypes = CommonClientServer.CollapseArray(SourcesTypes);

	LinkedObjectsTypesIndex = LinkedObjectsTypesIndex();

	IndexOf = SourcesTypes.UBound();
	While IndexOf >= 0 Do

		SourceType = SourcesTypes[IndexOf];
		If LinkedObjectsTypesIndex[SourceType] = Undefined Then
			SourcesTypes.Delete(IndexOf);
		EndIf;

		IndexOf = IndexOf - 1;

	EndDo;

	Return ?(SourcesTypes.Count() > 0, New TypeDescription(SourcesTypes), Undefined);

EndFunction

Procedure FillSourcesTypes(SourcesTypes, Sources)

	For Each Source In Sources Do
		If Not Common.MetadataObjectAvailableByFunctionalOptions(Source.Metadata) Then
			Continue;
		EndIf;

		If TypeOf(Source.DataRefType) = Type("Type") Then
			SourcesTypes.Add(Source.DataRefType);
		ElsIf TypeOf(Source.DataRefType) = Type("TypeDescription") Then
			For Each Type In Source.DataRefType.Types() Do
				MetadataObject = Metadata.FindByType(Type);
				If MetadataObject = Undefined
					Or Not Common.MetadataObjectAvailableByFunctionalOptions(MetadataObject) Then
					Continue;
				EndIf;
				SourcesTypes.Add(Type);
			EndDo;
		EndIf;

		FillSourcesTypes(SourcesTypes, Source.Rows);
	EndDo;

EndProcedure

Function LinkedObjectsTypesIndex()

	IndexOf = New Map;

	RelatedObjectsMetadata = Metadata.FilterCriteria.RelatedDocuments;
	LinkedObjectsTypes = RelatedObjectsMetadata.Type.Types();
	CommandParameterType = Metadata.CommonCommands.RelatedDocuments.CommandParameterType;

	For Each LinkedObjectType In LinkedObjectsTypes Do

		If Not CommandParameterType.ContainsType(LinkedObjectType) Then
			IndexOf.Insert(LinkedObjectType, True);
		EndIf;

	EndDo;

	Return IndexOf;

EndFunction

#EndRegion