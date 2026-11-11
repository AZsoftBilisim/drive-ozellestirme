///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	FieldsRestricted = New Array;
	FieldsRestricted.Add("DestinationUUID");
	FieldsRestricted.Add("DestinationType");
	FieldsRestricted.Add("SourceType");
	FieldsRestricted.Add("InfobaseNode");
	FieldsRestricted.Add("SourceUUIDString");
	FieldsRestricted.Add("ObjectExportedByRef");
	FieldsRestricted.Add("SourceUUID");
	
	List.SetRestrictionsForUseInOrder(FieldsRestricted);

EndProcedure

#EndRegion

