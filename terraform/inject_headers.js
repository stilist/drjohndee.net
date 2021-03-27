"use strict"

exports.handler = (event, context, callback) => {
  const globalHeaders = {
    // @see https://aws.amazon.com/blogs/networking-and-content-delivery/adding-http-security-headers-using-lambdaedge-and-amazon-cloudfront/
    "Content-Security-Policy": "default-src 'none'; font-src 'self'; frame-ancestors 'none'; img-src 'self'; script-src 'self'; style-src 'self'; object-src 'none'", // added `font-src`, `frame-ancestors`
    "Referrer-Policy": "same-origin",
    "Strict-Transport-Security": "max-age=63072000; includeSubdomains; preload",
    "X-XSS-Protection": "1; mode=block",
  }

  const assetHeaders = {
    ...globalHeaders,
    // @see https://w3c.github.io/webappsec-post-spectre-webdev/#static-subresources
    "Access-Control-Allow-Origin": "same-origin", // changed from suggested `*`
    "Content-Security-Policy": "sandbox",
    "Cross-Origin-Opener-Policy": "same-origin",
    "Cross-Origin-Resource-Policy": "same-origin",
    "Timing-Allow-Origin": "same-origin", // changed from suggested `*`
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
  }

  const documentHeaders = {
    ...globalHeaders,
    // @see https://w3c.github.io/webappsec-post-spectre-webdev/#documents-isolated
    "Cross-Origin-Opener-Policy": "same-origin", // changed from suggested `same-origin-allow-popups`
    "Cross-Origin-Resource-Policy": "same-origin",
    "Vary": "Sec-Fetch-Dest, Sec-Fetch-Mode, Sec-Fetch-Site, Sec-Fetch-User",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY", // changed from suggested `SAMEORIGIN`
  }

  // @see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-event-structure.html#lambda-event-structure-response-origin
  const cloudfrontObject = event.Records[0].cf
  const response = cloudfrontObject.response
  const responseHeaders = response.headers

  const requestedUri = cloudfrontObject.request.uri
  let typeSpecificHeaders
  if (/\.html/.test(requestedUri)) typeSpecificHeaders = documentHeaders
  else typeSpecificHeaders = assetHeaders
  for (const [key, value] of Object.entries(typeSpecificHeaders)) {
    responseHeaders[key.toLowerCase()] = [{
      key,
      value,
    }]
  }

  // XXX
  console.log({
    requestedUri,
    typeSpecificHeaders,
    responseHeaders,
  });

  callback(null, response)
}
