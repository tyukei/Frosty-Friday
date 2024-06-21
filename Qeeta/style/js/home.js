document.addEventListener('DOMContentLoaded', () => {
    const articleContainer = document.getElementById('article-container');

    // Assuming you have a server-side script that returns the list of HTML files as JSON.
    fetch("/path-to-server-endpoint/list-html-files") // Path to an endpoint that lists HTML files
        .then(response => response.json()) // Expecting a JSON response with file names
        .then(files => {
            files.forEach(file => {
                fetch(`../../html/${file}`) // Fetch each HTML file
                    .then(response => {
                        if (!response.ok) {
                            throw new Error('Network response was not ok ' + response.statusText);
                        }
                        return response.text();
                    })
                    .then(html => {
                        const articleDiv = document.createElement('div'); // Create a new div for each article
                        articleDiv.classList.add('article');
                        articleDiv.innerHTML = html; // Set the content of the div to the HTML file content
                        articleContainer.appendChild(articleDiv); // Append the article to the container
                    })
                    .catch(error => {
                        console.error('There has been a problem with your fetch operation:', error);
                    });
            });
        })
        .catch(error => console.error('Error loading articles:', error));
});
