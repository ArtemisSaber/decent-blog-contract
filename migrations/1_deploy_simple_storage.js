const BlogPost = artifacts.require('./BlogStorage')

module.exports = function (deployer) {
    deployer.deploy(BlogPost)
}
