///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region InterfaceImplementation

// See AttachableCommandsOverridable.OnDefineAttachableCommandsKinds
Procedure OnDefineAttachableCommandsKinds(AttachableCommandsKinds) Export
	
	If AttachableCommandsKinds.Find("Administration", "Name") = Undefined Then
	
		Kind = AttachableCommandsKinds.Add();
		Kind.Name         = "Administration";
		Kind.SubmenuName  = "Service";
		Kind.Title   = NStr("vi = 'Công cụ';
							|ru = 'Сервис';
							|en = 'Service'; fa = 'خدمت';
							|it = 'Servizio di assistenza';
							|pl = 'Service';
							|tr = 'Servis'");
		Kind.Order     = 80;
		Kind.Picture    = PictureLib.ServiceSubmenu;
		Kind.Representation = ButtonRepresentation.PictureAndText;	
	
	EndIf;
	
EndProcedure

// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export

	AttachedObjects = New Array;
	BatchEditObjectsOverridable.OnDefineObjectsWithBatchObjectsModificationCommand(AttachedObjects);
	For Each AttachedObject In AttachedObjects Do
					
		If AccessRight("Update", AttachedObject) 
			And Sources.Rows.Find(AttachedObject, "Metadata") <> Undefined Then
				
			Command = Commands.Add();
			Command.Kind = "Administration";
			Command.Importance = "SeeAlso";
			Command.Presentation = NStr("vi = 'Thay đổi đối tượng đã chọn...';
										|ru = 'Изменить выделенные...';
										|en = 'Edit selected…'; fa = 'ویرایش انتخاب‌شده‌ها…';
										|it = 'Modifica selezionati...';
										|pl = 'Zmień zaznaczone...';
										|tr = 'Seçilenleri değiştir...'");
			Command.WriteMode = "NotWrite";
			Command.Purpose = "ForList";
			Command.MultipleChoice = True;
			Command.Handler = "BatchEditObjectsClient.HandlerCommands";
			Command.OnlyInAllActions = True;
			Command.Order = 20;
			
			StringParts1 = StrSplit(AttachedObject.FullName(), ".", True);
			StringParts1[0] = StringParts1[0] + "Ref";
			Command.ParameterType = New TypeDescription(StrConcat(StringParts1, "."));
		EndIf;	
	
	EndDo;	

EndProcedure

#EndRegion

#EndRegion