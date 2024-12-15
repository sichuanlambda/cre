document.addEventListener('DOMContentLoaded', function() {
  const fetchLogoBtn = document.getElementById('fetchLogoBtn');
  if (fetchLogoBtn) {
    fetchLogoBtn.addEventListener('click', initiateFetch);
  }
});

async function initiateFetch() {
  const websiteUrl = document.getElementById('website_url').value;
  const statusDiv = document.getElementById('status');
  const resultDiv = document.getElementById('result');

  if (!websiteUrl) {
    alert('Please enter a website URL');
    return;
  }

  // Show loading state
  statusDiv.classList.remove('hidden');
  resultDiv.classList.add('hidden');
  
  try {
    const response = await fetch('/logo_fetcher/fetch', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ website_url: websiteUrl })
    });

    console.log('Response status:', response.status); // Debug log
    
    const data = await response.json();
    console.log('Response data:', data); // Debug log
    
    if (data.status === 'success') {
      showResult(data.logo_url);
    } else {
      showError(data.message || 'Failed to fetch logo');
    }
  } catch (error) {
    console.error('Fetch error:', error); // Debug log
    showError('Error: ' + error.message);
  }
}

function showResult(logoUrl) {
  const statusDiv = document.getElementById('status');
  const resultDiv = document.getElementById('result');
  
  statusDiv.classList.add('hidden');
  resultDiv.classList.remove('hidden');
  
  document.getElementById('logoImage').src = logoUrl;
  document.getElementById('logoUrl').value = logoUrl;
}

function showError(message) {
  const statusDiv = document.getElementById('status');
  statusDiv.innerHTML = `<div class="text-red-600">${message}</div>`;
}

function copyLogoUrl() {
  const logoUrl = document.getElementById('logoUrl');
  logoUrl.select();
  document.execCommand('copy');
  
  // Show feedback
  const button = event.target;
  const originalText = button.textContent;
  button.textContent = 'Copied!';
  setTimeout(() => {
    button.textContent = originalText;
  }, 2000);
} 