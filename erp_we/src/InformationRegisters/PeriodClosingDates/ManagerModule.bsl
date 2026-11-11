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
	
	// ACC:336-off - No. 737.3 Role check (as the right is always granted).
	Restriction.Text =
	"AllowRead
	|WHERE
	|	  (    IsInRole(ReadPeriodEndClosingDates)
	|	   OR IsInRole(AddEditPeriodClosingDates))
	|	AND (    VALUETYPE(User) = TYPE(Catalog.Users)
	|	   OR VALUETYPE(User) = TYPE(Catalog.UserGroups)
	|	   OR VALUETYPE(User) = TYPE(Catalog.ExternalUsers)
	|	   OR VALUETYPE(User) = TYPE(Catalog.ExternalUsersGroups)
	|	   OR User = VALUE(Enum.PeriodClosingDatesPurposeTypes.ForAllUsers))
	|	OR
	|	  (    IsInRole(ReadDataImportRestrictionDates)
	|	   OR IsInRole(AddEditDataImportRestrictionDates))
	|	AND VALUETYPE(User) <> TYPE(Catalog.Users)
	|	AND VALUETYPE(User) <> TYPE(Catalog.UserGroups)
	|	AND VALUETYPE(User) <> TYPE(Catalog.ExternalUsers)
	|	AND VALUETYPE(User) <> TYPE(Catalog.ExternalUsersGroups)
	|	AND User <> UNDEFINED
	|	AND User <> VALUE(Enum.PeriodClosingDatesPurposeTypes.EmptyRef)
	|	AND User <> VALUE(Enum.PeriodClosingDatesPurposeTypes.ForAllUsers)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	  IsInRole(AddEditPeriodClosingDates)
	|	AND (    VALUETYPE(User) = TYPE(Catalog.Users)
	|	   OR VALUETYPE(User) = TYPE(Catalog.UserGroups)
	|	   OR VALUETYPE(User) = TYPE(Catalog.ExternalUsers)
	|	   OR VALUETYPE(User) = TYPE(Catalog.ExternalUsersGroups)
	|	   OR User = VALUE(Enum.PeriodClosingDatesPurposeTypes.ForAllUsers))
	|	OR
	|	  IsInRole(AddEditDataImportRestrictionDates)
	|	AND VALUETYPE(User) <> TYPE(Catalog.Users)
	|	AND VALUETYPE(User) <> TYPE(Catalog.UserGroups)
	|	AND VALUETYPE(User) <> TYPE(Catalog.ExternalUsers)
	|	AND VALUETYPE(User) <> TYPE(Catalog.ExternalUsersGroups)
	|	AND User <> UNDEFINED
	|	AND User <> VALUE(Enum.PeriodClosingDatesPurposeTypes.EmptyRef)
	|	AND User <> VALUE(Enum.PeriodClosingDatesPurposeTypes.ForAllUsers)";
	// ACC:336-on
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf
