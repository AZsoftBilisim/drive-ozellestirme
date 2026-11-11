///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Defines print form templates that support multiple languages.
// 
// Parameters:
//  Templates - Array of MetadataObjectTemplate
//
Procedure WhenDefiningAvailableForTranslationLayouts(Templates) Export
	
	Templates.Add(Metadata.DataProcessors.PrintCommercialInvoices.Templates.PF_MXL_Invoice);
	Templates.Add(Metadata.DataProcessors.PrintCommercialInvoices.Templates.PF_MXL_DebitCreditNote);
	Templates.Add(Metadata.Documents.RequestForReturnOfGoodsFromCustomer.Templates.PF_MXL_ReturnRequest);
	Templates.Add(Metadata.DataProcessors.PrintOrderForGoodsServices.Templates.PF_MXL_SalesOrder);
	Templates.Add(Metadata.DataProcessors.PrintOrderForGoodsServices.Templates.PF_MXL_PurchaseOrder);
	Templates.Add(Metadata.Documents.MaterialProviderOrder2_5.Templates.PF_MXL_MaterialProviderOrder);
	Templates.Add(Metadata.Documents.SubcontractOrder2_5.Templates.PF_MXL_SubcontractOrder2_5);
	Templates.Add(Metadata.Documents.SubcontractOrder2_5.Templates.PF_MXL_SubcontractServicesOrder2_5);
EndProcedure

#EndRegion
